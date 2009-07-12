package CatalystX::SimpleLogin::ControllerRole::Login;
use MooseX::MethodAttributes ();
use Moose::Role -traits => 'MethodAttributes';
use Moose::Autobox;
use MooseX::Types::Moose qw/ ArrayRef ClassName Object /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use File::ShareDir qw/module_dir/;
use List::MoreUtils qw/uniq/;
use CatalystX::SimpleLogin::Form::Login;
use namespace::autoclean;

has 'username_field' => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    required => 1,
    default => 'username',
);

has 'password_field' => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    required => 1,
    default => 'password',
);

has 'extra_auth_fields' => (
    isa => ArrayRef[NonEmptySimpleStr],
    is => 'ro',
    default => sub { [] },
);

has login_form_class => (
    isa => ClassName,
    is => 'ro',
    default => 'CatalystX::SimpleLogin::Form::Login',
);

has login_form => (
    isa => Object,
    is => 'ro',
    lazy => 1,
    default => sub { shift->login_form_class->new },
);

sub _auth_fields {
    my ($self) = @_;

    return @{ $self->extra_auth_fields },
        map { $self->$_() } qw/ username_field password_field /;
}

sub login : Chained('/') PathPart('login') Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{additional_template_paths} =
        [ uniq(
            @{$c->stash->{additional_template_paths}||[]},
            module_dir('CatalystX::SimpleLogin::Controller::Login') . '/'
            . 'tt'
        ) ];
    $c->stash->{form} = $self->login_form;
}

sub login_GET {}

sub login_POST {
    my ($self, $c) = @_;

    my $form = $self->login_form;
    my $p = $c->req->body_parameters;
    $form->process(params => $p);
    if ($form->validated) {
        # FIXME - pull values out of form again.
        if ($c->authenticate({
            map { $_ => ($p->{$_}->flatten)[0] } $self->_auth_fields
        })) {
            $c->res->redirect($self->redirect_after_login_uri($c));
        }
    }
}

sub redirect_after_login_uri {
    my ($self, $c) = @_;
    $c->uri_for('/');
}

1;

