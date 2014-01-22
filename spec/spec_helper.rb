require 'webmock/rspec'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    directory = File.join(tmpdir, name)
    FileUtils.mkdir directory
    directory
  end

  let(:tmpdir) { Dir.mktmpdir }
end

def stub_github_for(repo_name, some_sha)
  latest_commit = OpenStruct.new(sha: some_sha)

  Octokit::Client.any_instance.stub(:octocat).and_return 'ascii kitten proves auth validity'
  Octokit::Client.any_instance.stub(:commits).with(repo_name).and_return [latest_commit]

  zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_sha}.tar.gz"
  Octokit::Client.any_instance.stub(:archive_link).with(repo_name, ref: latest_commit.sha).and_return(zipped_repo_url)

  zipped_repo = MarkdownRepoFixture.tarball repo_name.split('/').last, some_sha
  stub_request(:get, zipped_repo_url).to_return(
      :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
  )
end

require_relative '../lib/bookbinder'
require_relative 'fixtures/markdown_repo_fixture'

GEM_ROOT = Dir.pwd

RSpec.configure do |config|
  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil

    #the Github API token must be in the ENV or tests will fail.
    ENV['GITHUB_API_TOKEN'] = 'foo'
  end

  config.before do
    BookbinderLogger.stub(:log) {  }
  end

  module SpecHelperMethods
    def squelch_middleman_output
      Thor::Shell::Basic.any_instance.stub(:say_status) {}
      Middleman::Logger.any_instance.stub(:add) {}
    end

    def write_markdown_source_file(path_under_source_dir, title, content = nil, breadcrumb_title = nil)
      full_path = File.join(source_dir, path_under_source_dir)
      full_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p full_pathname.dirname
      breadcrumb_code = breadcrumb_title ? "breadcrumb: #{breadcrumb_title}\n" : ''
      final_content = "---\ntitle: #{title}\n#{breadcrumb_code}---\n#{content}"
      File.open(full_path, 'w') { |f| f.write(final_content) }
    end

    def run_middleman(template_variables = {})
      MiddlemanRunner.new.run tmpdir, template_variables
    end
  end

  config.include SpecHelperMethods
end



