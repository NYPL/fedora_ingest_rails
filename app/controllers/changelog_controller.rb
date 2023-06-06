class ChangelogController < ApplicationController
  layout false
  http_basic_authenticate_with name: "admin", password: "speakingofchanges"

  def index
    changelog_path = Rails.root.join('CHANGELOG.md')
    changelog_contents = File.read(changelog_path)
    html_renderer = Redcarpet::Render::HTML.new
    markdown_renderer = Redcarpet::Markdown.new(html_renderer)
    render html: markdown_renderer.render(changelog_contents).html_safe
  end
end
