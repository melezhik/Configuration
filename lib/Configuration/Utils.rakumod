use v6.d;
use experimental :cached;
unit module Configuration::Utils;
use Configuration::Node;

sub choose-pars(&block, :$parent, :$root) is export {
    my %pars is Set = &block.signature.params.grep({ .named }).map({ .name.substr(1) });
    %(
        |(:$parent if %pars<parent>),
        |(:$root   if %pars<root>),
    )
}

sub generate-builder-class(Configuration::Node:U $node) is cached is export {
    my $builder = Metamodel::ClassHOW.new_type: :name($node.^name ~ "Builder");
    $builder.^add_parent: $node;
    for $node.^attributes.grep(*.has_accessor) -> Attribute $attr (::T :$type, |) {
        my $name = $attr.name.substr: 2;
        my $meth = do if $attr.type !~~ Configuration::Node {
            $builder.^add_method: $name, method () is rw {
                Proxy.new:
                        FETCH => -> $self {
                            %*DATA{$name}:exists
                                    ?? %*DATA{$name}
                                    !! $attr.build // $attr.type
                        },
                        STORE => -> $self, T \value {
                            X::TypeCheck::Assignment.new(got => value, expected => $attr.type).throw unless value ~~ $attr
                            .type;
                            %*DATA{$name} = value
                        }
            }
        } else {
            $builder.^add_method: $name, method (&block) {
                my $builder = generate-builder-class($attr.type);
                my %parent := %*DATA;
                {
                    my %*DATA;
                    block $builder, |choose-pars(&block, :%parent, :root(%*ROOT));
                    %parent{$name} = $attr.type.new(|%*DATA);
                }
            }
        }
        $meth.set_why: $_ with $attr.WHY;
    }
    $builder.^compose;
    $builder
}