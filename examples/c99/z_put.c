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

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "zenoh-pico.h"

int main(int argc, char **argv)
{
    z_init_logger();

    char *keyexpr = "demo/example/zenoh-pico-put";
    char *value = "Pub from Pico!";
    char *locator = NULL;

    int opt;
    while ((opt = getopt (argc, argv, "k:v:e:")) != -1) {
        switch (opt) {
            case 'k':
                keyexpr = optarg;
                break;
            case 'v':
                value = optarg;
                break;
            case 'e':
                locator = optarg;
                break;
            case '?':
                if (optopt == 'k' || optopt == 'v' || optopt == 'e') {
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                } else {
                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                }
                return 1;
            default:
                exit(-1);
        }
    }

    z_owned_config_t config = zp_config_default();
    if (locator != NULL) {
        zp_config_insert(z_config_loan(&config), Z_CONFIG_PEER_KEY, z_string_make(locator));
    }

    printf("Opening session...\n");
    z_owned_session_t s = z_open(z_config_move(&config));
    if (!z_session_check(&s)) {
        printf("Unable to open session!\n");
        exit(-1);
    }

    // Start the receive and the session lease loop for zenoh-pico
    zp_start_read_task(z_session_loan(&s));
    zp_start_lease_task(z_session_loan(&s));

    printf("Declaring key expression '%s'...\n", keyexpr);
    z_owned_keyexpr_t ke = z_declare_keyexpr(z_session_loan(&s), z_keyexpr(keyexpr));
    if (!z_keyexpr_check(&ke)) {
        printf("Unable to declare key expression!\n");
        exit(-1);
    }

    printf("Putting Data ('%s': '%s')...\n", keyexpr, value);
    if (z_put(z_session_loan(&s), z_keyexpr_loan(&ke), (const uint8_t *)value, strlen(value), NULL) < 0) {
        printf("Oh no! Put has failed...\n");
    }

    z_undeclare_keyexpr(z_session_loan(&s), z_keyexpr_move(&ke));

    // Stop the receive and the session lease loop for zenoh-pico
    zp_stop_read_task(z_session_loan(&s));
    zp_stop_lease_task(z_session_loan(&s));

    z_close(z_session_move(&s));
    return 0;
}
