# Example

## Configuration (`my-conf.rakuconfig`)

```raku
config {
    .a = 1;
    .c = 42;
}
```

## Program using the configuration:

```raku
use Configuration;

class Test1Config {
    has Int $.a;
    has Int $.b = $!a * 2;
    has Int $.c = $!b * 3;
}

say await config-run(Test1Config, :file<examples/test1.rakuconfig>)
```

This, with that configuration, will print:


```raku
Test1Config+{Configuration::Node}.new(a => 1, b => 2, c => 42)
```

But you could also make it reload if the file changes:

```raku
use Configuration;

class Test1Config {
    has Int $.a;
    has Int $.b = $!a * 2;
    has Int $.c = $!b * 3;
}

react whenever config-run(Test1Config, :file<./my-conf.rakuconfig>, :signal(SIGUSR1)) {
    say "Configuration changed: { .raku }";
}
```

The whenever will be called every time the configuration change and SIGUSR1 is sent to the process.
It also can watch the configuration file:

```raku
use Configuration;

class Test1Config {
    has Int $.a;
    has Int $.b = $!a * 2;
    has Int $.c = $!b * 3;
}

react whenever config-run(Test1Config, :file<./my-conf.rakuconfig>, :watch) {
    say "Configuration changed: { .raku }";
}
```

And it will reload whenever the file changes.
The `whenever`, with the current configuration, will receive this object:

```raku
Test1Config+{Configuration::Node}.new(a => 1, b => 2, c => 42)
```

If your code is changed to something like this:

```raku
use Configuration;

class DBConfig {
    has Str $.host = 'localhost';
    has Int $.port = 5432;
    has Str $.dbname;
}

class Test1Config {
    has Int $.a;
    has Int $.b = $!a * 2;
    has Int $.c = $!b * 3;
    has DBConfig $.db .= new;
}

react whenever config-run(Test1Config, :file<./my-conf.rakuconfig>, :watch) {
    say "Configuration changed: { .raku }";
}

```

Your `whenever` will receive an object like this:

```raku
Test1Config+{Configuration::Node}.new(a => 1, b => 2, c => 42, db => DBConfig.new(host => "localhost", port => 5432, dbname => Str))
```

And if you want to change your configuration to populate the DB config, you can do that with something like this:

```raku
config {
    .a = 1;
    .c = 42;
    .db: {
        .dbname = "my-database";
    }
}
```

And it will generate the object:

```raku
Test1Config+{Configuration::Node}.new(a => 1, b => 2, c => 42, db => DBConfig+{Configuration::Node}.new(host => "localhost", port => 5432, dbname => "my-database"))
```

An example with Cro could look like this:

```raku
use Cro::HTTP::Router;
use Cro::HTTP::Server;

use Configuration;

my $application = route {
    get -> 'greet', $name {
        content 'text/plain', "Hello, $name!";
    }
}

class ServerConfig {
    has Str $.host = 'localhost';
    has Int $.port = 80;
}

my Cro::Service $server;
react {
    whenever config-run(ServerConfig, :file<examples/cro.rakuconfig>, :watch) -> $config {
        my $old = $server;
        $server = Cro::HTTP::Server.new:
                  :host($config.host), :port($config.port), :$application;
        $server.start;
        say "server started on { $config.host }:{ $config.port }";
        .stop with $old;
    }
    whenever signal(SIGINT) {
        $server.stop;
        exit;
    }
}
```
