package MT::Plugin::RebuildBlogByID;
use strict;
use MT;
use MT::Plugin;

use MT::Util qw ( start_background_task );

our $VERSION = "1.0.0";

@MT::Plugin::RebuildBlogByID::ISA = qw(MT::Plugin);

my $plugin = new MT::Plugin::RebuildBlogByID({
    id => 'RebuildBlogByID',
    key => 'rebuildblogbyid',
    name => 'RebuildBlogByID',
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
	version => $VERSION,
    l10n_class => 'RebuildBlogByID::L10N',
    settings => new MT::PluginSettings([
        [ 'rebuild_blog_ids_at_saving_entry', { Default => '' } ],
        [ 'rebuild_blog_ids_at_saving_page', { Default => '' } ],
    ]),
    blog_config_template => 'rebuildblogbyid_config_blog.tmpl',
});

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            'cms_post_save.entry',
                => \&_post_save_entry,
            'cms_post_save.page',
                => \&_post_save_entry,
            'api_post_save.entry',
                => \&_post_save_entry,
            'api_post_save.page',
                => \&_post_save_entry,
            'cms_post_delete.entry'
                => \&_post_save_entry,
            'cms_post_delete.page'
                => \&_post_save_entry,
        },
   } );
}

######################################### Mainroutine #########################################

sub _post_save_entry {
	my ( $eh, $app, $obj, $original ) = @_;
	my $blog_ids;
	if ( $obj->class eq 'entry' ) {
	    $blog_ids = $plugin->get_config_value( 'rebuild_blog_ids_at_saving_entry', 'blog:' . $obj->blog_id );
	} elsif ( $obj->class eq 'page' ) {
	    $blog_ids = $plugin->get_config_value( 'rebuild_blog_ids_at_saving_page', 'blog:' . $obj->blog_id );
	}
	$app = MT->instance;
	if ( $blog_ids && $app ) {
	    my @blog_ids = split( /\,/, $blog_ids );
        MT::Util::start_background_task( sub { 
                                               foreach my $blog_id (@blog_ids) {
                                                   if ( ( my $blog = MT::Blog->load( { id => $blog_id } ) ) && ( $app->rebuild( BlogID => $blog_id ) ) ) {
                                                       $app->log( $plugin->translate( 'Rebuild Blog [_1]', $blog->name ) );
                                                   }
                                               }
                                             }
                                       );
	}
1;
}

1;



