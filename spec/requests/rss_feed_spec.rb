require File::expand_path('../../spec_helper', __FILE__)

describe "RSS-Feed" do

  before(:all) do
    cleanup_database
    create_default_userset
    @page = Page.create(title: 'A Twitter page', body: "Lorem Twittum", is_draft: false)
    @page.translate!
    @page.save
    @blog1 = Blog.create(title: "Blog One", is_draft: false)
    @posting = @blog1.postings.create(title: "Posting one", body: "lorem ipsum with <p>some<br></p> html", is_draft: false, user_id: User.first.id)
    @draft   = @blog1.postings.create(title: "Posting Draft", body: "A Posting Draft", is_draft: true, user_id: User.first.id)
  end
  
  it "should feed pages" do
    visit feed_path
    page.should have_content "TESTFEED"
    page.should have_content "A Twitter page"
    page.should have_content "Lorem Twittum"
  end
  
  it "should feed postings which are not marked as draft" do
    visit feed_path
    page.should have_content "lorem ipsum with some html"
    page.should_not have_content "A Posting Draft"
  end
  
end
