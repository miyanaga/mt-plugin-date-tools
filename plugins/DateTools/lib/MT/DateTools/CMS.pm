package MT::DateTools::CMS;

use strict;
use warnings;

use MT::Util;

sub load_registry {
    my $app = MT->instance;
    return {} unless $app->config('AllowPastUnpublishedOn');

    {
        callbacks => {
            'init_request'          => \&on_init_request,
            'cms_pre_save.entry'    => \&cms_pre_save_entry,
            'cms_pre_save.page'     => \&cms_pre_save_entry,
        }
    };
}

sub on_init_request {
    my ( $cb, $app ) = @_;

    my $uo_d = $app->param('unpublished_on_date');
    my $uo_t = $app->param('unpublished_on_time');

    if ( $uo_d || $uo_t ) {
        $app->param('_unpublished_on_date', $uo_d);
        $app->param('_unpublished_on_time', $uo_t);
        $app->param('unpublished_on_date', '');
        $app->param('unpublished_on_time', '');
     }

     1;
}

sub cms_pre_save_entry {
    my ( $cb, $app, $entry, $orig ) = @_;
    my $blog = $app->blog or return 1;
    my %param;

    my $uo_d = $app->param('_unpublished_on_date');
    my $uo_t = $app->param('_unpublished_on_time');

    if ( $uo_d ) {
        $app->param('unpublished_on_date', $uo_d);
        $app->param('unpublished_on_time', $uo_t);
        $app->param('_unpublished_on_date', '');
        $app->param('_unpublished_on_time', '');
        $uo_t ||= '00:00:00';
    } else {
        return 1;
    }

    # From MT::CMS::Entry
    my $uo    = $uo_d . ' ' . $uo_t;
    $param{error} = $app->translate(
        "Invalid date '[_1]'; 'Unpublished on' dates must be in the format YYYY-MM-DD HH:MM:SS.",
        $uo
        )
        unless ( $uo
        =~ m!^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$!
        );
    unless ( $param{error} ) {
        my $s = $6 || 0;
        $param{error} = $app->translate(
            "Invalid date '[_1]'; 'Unpublished on' dates should be real dates.",
            $uo
            )
            if (
               $s > 59
            || $s < 0
            || $5 > 59
            || $5 < 0
            || $4 > 23
            || $4 < 0
            || $2 > 12
            || $2 < 1
            || $3 < 1
            || ( MT::Util::days_in( $2, $1 ) < $3
                && !MT::Util::leap_day( $0, $1, $2 ) )
            );
    }
    my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $1, $2, $3, $4, $5,
        ( $6 || 0 );

    # Check and draft
    require MT::DateTime;
    unless ( $param{error} ) {
        $entry->status(MT::Entry::HOLD())
            if (
            MT::DateTime->compare(
                blog => $blog,
                a    => { value => time(), type => 'epoch' },
                b    => $ts
            ) > 0
            );
    }
    if ( !$param{error} && $entry->authored_on ) {
        $entry->status(MT::Entry::HOLD())
            if (
            MT::DateTime->compare(
                blog => $blog,
                a    => $entry->authored_on,
                b    => $ts
            ) > 0
            );
    }

    return $cb->error($param{error}) if $param{error};
    $entry->unpublished_on($ts);

    1;
}

1;