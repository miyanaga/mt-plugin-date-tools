package MT::DateTools::Tags;

use strict;
use warnings;

use MT::Util;

sub plugin { MT->component('DateTools') }

sub hdlr_unix_timestamp {
    my ( $text, $arg, $ctx ) = @_;

    return $ctx->error(plugin->translate('Use like this: format="%Y%m%d%H%M%S" unix_timestamp="1"'))
        unless $text =~ /^[0-9]{14}$/;

    my $blog = $ctx->stash('blog');
    MT::Util::ts2epoch($blog, $text, 0);
}

sub hdlr_EntryUnpublishingDate {
    my ( $ctx, $args ) = @_;
    my $e = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    return $ctx->error(plugin->translate('This Movable Type does not support scheduled unpublishing.'))
        unless $e->can('unpublished_on');
    $args->{ts} = $e->unpublished_on;
    return $ctx->build_date($args);
}

1;