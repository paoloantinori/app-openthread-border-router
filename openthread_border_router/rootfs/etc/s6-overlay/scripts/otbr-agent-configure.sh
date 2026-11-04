#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configure OTBR depending on add-on settings
# ==============================================================================

# shellcheck source=./openthread_border_router/rootfs/etc/s6-overlay/scripts/otbr-agent-common
. /etc/s6-overlay/scripts/otbr-agent-common

ot-ctl trel enable

if bashio::config.true 'nat64'; then
    if bashio::config.false 'border_routing'; then
        bashio::exit.nok \
            "The options nat64 and border_routing cannot be combined: the NAT64" \
            "prefix is published into the Thread network by border routing."
    fi
    bashio::log.info "Enabling NAT64."
    ot-ctl nat64 enable
    ot-ctl dns server upstream enable
fi

mdns_localhostname="$(hostname)-otbr"
bashio::log.info "Setting OpenThread mDNS local hostname to ${mdns_localhostname}."
ot-ctl mdns localhostname "${mdns_localhostname}"
ot-ctl mdns enable

# To avoid asymmetric link quality the TX power from the controller should not
# exceed that of what other Thread routers devices typically use.
ot-ctl txpower 6

if bashio::config.false 'border_routing'; then
    bashio::log.info \
        "Border routing disabled by configuration: stopping the Backbone Router" \
        "and the Router Advertisements on the infrastructure network."
    # A transient CLI error must not fail this oneshot and take the whole
    # user bundle down with it: log loud and let the otbr-border-routing
    # enforcer re-assert the disable within 60 seconds.
    otbr_cli bbr disable || true
    otbr_cli br disable || true
fi
