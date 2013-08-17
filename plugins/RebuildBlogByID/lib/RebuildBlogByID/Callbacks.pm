package RebuildBlogByID::Callbacks;
use strict;

sub _cb_cms_post_save_entry {
	my ( $eh, $app, $obj, $original ) = @_;
    my $plugin = MT->component( 'RebuildBlogByID' );
	if ( $plugin->get_config_value( 'only_pulish_status', 'blog:' . $obj->blog_id ) ) {
	    return 1 unless $obj->status eq MT::Entry::RELEASE();
	}
	my $blog_ids = $obj->class eq 'entry'
	                    ? $plugin->get_config_value( 'rebuild_blog_ids_at_saving_entry', 'blog:' . $obj->blog_id )
	                    : $plugin->get_config_value( 'rebuild_blog_ids_at_saving_page', 'blog:' . $obj->blog_id );
	if ( $blog_ids ) {
	    my @blog_ids = split( /\s*,\s*/, $blog_ids );
        MT::Util::start_background_task( sub { 
                                               for my $blog_id ( @blog_ids ) {
                                                   my $blog = MT::Blog->load( { id => $blog_id } );
                                                   if ( $blog ) {
                                                       if ( $app->rebuild( BlogID => $blog->id ) ) {
                                                           $app->log( $plugin->translate( 'Rebuild Blog [_1]', $blog->name ) );
                                                       }
                                                   }
                                               }
                                             }
                                       );
	}
}

1;
