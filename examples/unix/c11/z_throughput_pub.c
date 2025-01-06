//
// Copyright (c) 2022 ZettaScale Technology
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0, or the Apache License, Version 2.0
// which is available at https://www.apache.org/licenses/LICENSE-2.0.
//
// SPDX-License-Identifier: EPL-2.0 OR Apache-2.0
//
// Contributors:
//   ZettaScale Zenoh Team, <zenoh@zettascale.tech>
//

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "zenoh-pico.h"
#include "zenoh-pico/system/platform.h"

#if Z_FEATURE_SUBSCRIPTION == 1 && Z_FEATURE_PUBLICATION == 1 && Z_FEATURE_MULTI_THREAD == 1

#define DEFAULT_PKT_SIZE 1024
#define DEFAULT_PING_NB 100
#define DEFAULT_WARMUP_MS 3000

static z_owned_condvar_t cond;
static z_owned_mutex_t mutex;
static unsigned long total_received_bytes = 0;
static z_clock_t start_time;
static bool warmup_ok = false;
static unsigned long elapsed_us = 0;
struct args_t {
    unsigned int size;             // -s
    unsigned int number_of_pings;  // -n
    unsigned int warmup_ms;        // -w
    uint8_t help_requested;        // -h
};

struct args_t parse_args(int argc, char** argv);

void callback(z_loaned_sample_t* sample, void* context) {
    // total_received_bytes += _z_bytes_len(&sample->payload);
    // printf("total_received_bytes:%d\n", total_received_bytes);
    // printf("number_of_ping:%d\n",((struct args_t*)context)->number_of_pings);
    // printf("context_size:%d\n", ((struct args_t*)context)->size);
    // if (total_received_bytes >= ((struct args_t*)context)->number_of_pings * ((struct args_t*)context)->size && warmup_ok == true) {
    //     unsigned long elapsed_us = 0;
    //     elapsed_us = z_clock_elapsed_us(&start_time);
    //     printf("elapsed time:%d\n", elapsed_us);
    //     double throughput = (double)total_received_bytes * 8 * 1000 * 1000 / (elapsed_us * 1024 * 1024);
    //     printf("throughput: %.2f Mbps\n", throughput);
    // }else{
    //     printf("not done\n");
    // }
    if(warmup_ok == true){
        elapsed_us = z_clock_elapsed_us(&start_time);
        //example: 1024 * 8 bit / elapsed_s * 1024*  1024 => Mbps
        double throughput = (double)((struct args_t*)context)->size * 8 * 1000 * 1000 / (elapsed_us * 1024 * 1024);
        printf("throughput: %.2f Mbps\n", throughput);
    }
    z_condvar_signal(z_loan_mut(cond));
}

void drop(void* context) {
    (void)context;
    z_drop(z_move(cond));
}

int main(int argc, char** argv) {
    struct args_t args = parse_args(argc, argv);
    if (args.help_requested) {
        printf(
            "\
        -n (optional, int, default=%d): the number of pings to be attempted\n\
        -s (optional, int, default=%d): the size of the payload embedded in the ping and repeated by the pong\n\
        -w (optional, int, default=%d): the warmup time in ms during which pings will be emitted but not measured\n\
        -c (optional, string): the path to a configuration file for the session. If this option isn't passed, the default configuration will be used.\n\
        ",
            DEFAULT_PKT_SIZE, DEFAULT_PING_NB, DEFAULT_WARMUP_MS);
        return 1;
    }

    z_mutex_init(&mutex);
    z_condvar_init(&cond);
    z_owned_config_t config;
    z_config_default(&config);
    z_owned_session_t session;
    if (z_open(&session, z_move(config), NULL) < 0) {
        printf("Unable to open session!\n");
        return -1;
    }

    if (zp_start_read_task(z_loan_mut(session), NULL) < 0 || zp_start_lease_task(z_loan_mut(session), NULL) < 0) {
        printf("Unable to start read and lease tasks\n");
        z_drop(z_move(session));
        return -1;
    }

    z_view_keyexpr_t ping;
    z_view_keyexpr_from_str_unchecked(&ping, "test/ping");
    z_view_keyexpr_t pong;
    z_view_keyexpr_from_str_unchecked(&pong, "test/pong");

    z_owned_publisher_t pub;
    if (z_declare_publisher(z_loan(session), &pub, z_loan(ping), NULL) < 0) {
        printf("Unable to declare publisher for key expression!\n");
        return -1;
    }

    z_owned_closure_sample_t respond;
    z_closure(&respond, callback, drop, &args);
    z_owned_subscriber_t sub;
    if (z_declare_subscriber(z_loan(session), &sub, z_loan(pong), z_move(respond), NULL) < 0) {
        printf("Unable to declare subscriber for key expression.\n");
        return -1;
    }

    uint8_t* data = z_malloc(args.size);
    for (unsigned int i = 0; i < args.size; i++) {
        data[i] = (uint8_t)(i % 10);
    }

    z_mutex_lock(z_loan_mut(mutex));
    if (args.warmup_ms) {
        printf("Warming up for %dms...\n", args.warmup_ms);
        z_clock_t warmup_start = z_clock_now();
        unsigned long elapsed_us = 0;
        while (elapsed_us < args.warmup_ms * 1000) {
            // Create payload
            z_owned_bytes_t payload;
            z_bytes_from_buf(&payload, data, args.size, NULL, NULL);

            z_publisher_put(z_loan(pub), z_move(payload), NULL);
            z_condvar_wait(z_loan_mut(cond), z_loan_mut(mutex));
            elapsed_us = z_clock_elapsed_us(&warmup_start);
        }
        warmup_ok = true;
    }

    for (unsigned int i = 0; i < args.number_of_pings; i++) {
        // Create payload
        z_owned_bytes_t payload;
        z_bytes_from_buf(&payload, data, args.size, NULL, NULL);
        
        start_time = z_clock_now();
        z_publisher_put(z_loan(pub), z_move(payload), NULL);
        z_condvar_wait(z_loan_mut(cond), z_loan_mut(mutex));
    }

    z_mutex_unlock(z_loan_mut(mutex));
    z_free(data);
    z_drop(z_move(pub));
    z_drop(z_move(sub));

    z_drop(z_move(session));
}

// 需要修改此处的getopt 如果使用SYLIXOS自带的getopt 会崩溃
char* zenoh_getopt(int argc, char** argv, char option) {
    for (int i = 0; i < argc; i++) {
        size_t len = strlen(argv[i]);
        if (len >= 2 && argv[i][0] == '-' && argv[i][1] == option) {
            if (len > 2 && argv[i][2] == '=') {
                return argv[i] + 3;
            } else if (i + 1 < argc) {
                return argv[i + 1];
            }
        }
    }
    return NULL;
}

struct args_t parse_args(int argc, char** argv) {
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            return (struct args_t){.help_requested = 1};
        }
    }
    char* arg = zenoh_getopt(argc, argv, 's');
    unsigned int size = DEFAULT_PKT_SIZE;
    if (arg) {
        size = (unsigned int)atoi(arg);
    }
    arg = zenoh_getopt(argc, argv, 'n');
    unsigned int number_of_pings = DEFAULT_PING_NB;
    if (arg) {
        number_of_pings = (unsigned int)atoi(arg);
    }
    arg = zenoh_getopt(argc, argv, 'w');
    unsigned int warmup_ms = DEFAULT_WARMUP_MS;
    if (arg) {
        warmup_ms = (unsigned int)atoi(arg);
    }
    return (struct args_t){
       .help_requested = 0,
       .size = size,
       .number_of_pings = number_of_pings,
       .warmup_ms = warmup_ms,
    };
}
#else
int main(void) {
    printf(
        "ERROR: Zenoh pico was compiled without Z_FEATURE_SUBSCRIPTION or Z_FEATURE_PUBLICATION or "
        "Z_FEATURE_MULTI_THREAD but this example requires them.\n");
    return -2;
}
#endif