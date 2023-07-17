# Test1Config exports many thing, 3 of them
# are the `config-run`, `get-config` and `config-supply`
# subs. COMMA seems to not be recognizing
# any of its exports (not even the config sub).
# That might be a bug on COMMA.
use Test1Config;

react {
    # Emits when anything changed on the file
    # I mean the values
    whenever config-run :file<examples/test1/test1.rakuconfig>, :watch {
        say "Configuration changed: { .raku }";
    }
    whenever Promise.in: 5 {
        # Simulate a different place on the code base
        # probably a different file. But in that case
        # it would need to `use Test1Config`.
        another-place;
    }
    whenever Supply.interval: 5 {
        # Gets the last configuration value
        say "the last config was: ", get-config;
    }
}

sub another-place {
    # Emits only when `.a` is changed
    config-supply(*.a).tap: { say ".a has changed: ", $_ }

    # Emits only when `.db.host` is changed
    config-supply(*.db.host).tap: { say ".db.host has changed: ", $_ }

    # Emits only when `.db` is changed
    config-supply(*.db).tap: { say ".db has changed: ", $_ }
}