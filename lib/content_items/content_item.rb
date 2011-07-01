# The ContentItem-class within this module can be used to make any model in
# your application to be 'blogabble'. Just derive from ContentItems::ContentItem
module ContentItem

  def self.included(base)
    base.extend ContentItem::ClassMethods
  end


  # Render :txt as markdown with Redcarpet
  module_function
  def markdown(txt)
    options = [
               :hard_wrap, :filter_html, :filter_styles, :autolink, 
               :no_intraemphasis, :fenced_code, :gh_blockcode
              ]
    doc = Nokogiri::HTML(Redcarpet.new(txt, *options).to_html)
    doc.search("//pre[@lang]").each do |pre|
      pre.replace Albino.colorize(pre.text.rstrip, pre[:lang])
    end
    doc.xpath('//body').to_s.html_safe
  end  
  # == ContentItem
  # Can be a 'Page', a 'Posting' or something else you want to be
  # * Commentable
  # * Rateable
  # * Able to display in RSS-feeds
  # * and more.
  #
  # Please note that you should use <code>stored_in :your_collection_name</code>
  # in your derived class. Otherwise Mongo will store all content_items in
  # one single collection named 'content_items_content_items' and properly this
  # will not what you will do. Though it may make sense in some cases.
  module ClassMethods
    def acts_as_content_item
      class_eval <<-EOV
        include Mongoid::Document
        include Mongoid::Timestamps
        include CoverPicture

        # ContentItems should have an unique title
        field :title
        index :title
        validates_presence_of :title
        validates_uniqueness_of :title

        # Will return a truncated version of the title if it exceeds the maximum
        # length of titles used in the menu (or wherever you can't display long titles)
        def short_title
          title.truncate(CONSTANTS['title_max_length'].to_i, :omission => '...')
        end


        # A standard <code>link_to 'Name', @page</code> will put in a link
        # to "/pages/OPBJECT_ID" but we want to see the title in the link
        # (Google prefers that). See: PagesController::permalinked
        def link_to_title
          short_title_for_url.txt_to_url
        end

        def render_intro
          content_for_intro
        end

        def render_for_html(txt)
          self.interpreter ||= :markdown
          case self.interpreter.to_sym
          when :markdown
            markdown(txt)
          when :textile
            RedCloth.new(txt).to_html
          when :simple_text
            txt.each_line.map do |line|
              '<p>' + line.strip + '</p>' unless line.strip.blank?
            end.compact.join("\n")
          else
            txt
          end.gsub( /ATTACHMENT[\d+]/ ) { |attachment|
            attachment_i = attachment.gsub( /\D/,'' ).to_i
            render_attachment(attachment_i)
          }.gsub( /COMPONENT[\d+]/ ) { |component|
            component_i = component.gsub( /\D/,'' ).to_i
            render_page_component(component_i)
          }
        end

        private
        def content_for_intro
          raise "ABSTRACT_METHOD_CALLED - Overwrite content_for_intro"
        end
        
        def render_attachment(idx)
          idx ||= 1
          idx -= 1
          if @context_view
            attachment = self.attachments[idx]
            if attachment
              if attachment.file_content_type =~ /image/
                @context_view.image_tag attachment.file.url(:medium)
              else
                @context_view.link_to attachment.file_file_name attachment.file.original
              end
            else
              "ATTACHMENT "+idx.to_s+" NOT FOUND"
            end
          end
        end
        
        def render_component(idx)
          "RENDER COMPONENT NOT IMPLEMENTED FOR #{self.class.to_s}"
        end
      EOV
    end
  end


end
