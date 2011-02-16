require 'test_helper'

class BuildTest < ActiveSupport::TestCase

  include WithTestRepo

  test "Project.ajax_reload? method with ajax_reload => always" do
    BigTuna.stubs(:ajax_reload).returns('always')

    build = Build.new

    build.status = Build::STATUS_IN_QUEUE
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_PROGRESS
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_OK
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_FAILED
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(build.ajax_reload?, "Should be true.")
  end

  test "Project.ajax_reload? method with ajax_reload => building" do
    BigTuna.stubs(:ajax_reload).returns('building')

    build = Build.new

    build.status = Build::STATUS_IN_QUEUE
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_PROGRESS
    assert(build.ajax_reload?, "Should be true.")

    build.status = Build::STATUS_OK
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_FAILED
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(!build.ajax_reload?, "Should be false.")
  end

  test "Project.ajax_reload? method with ajax_reload => false" do
    BigTuna.stubs(:ajax_reload).returns('false')

    build = Build.new

    build.status = Build::STATUS_IN_QUEUE
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_PROGRESS
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_OK
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_FAILED
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(!build.ajax_reload?, "Should be false.")

    build.status = Build::STATUS_BUILDER_ERROR
    assert(!build.ajax_reload?, "Should be false.")
  end

  test "invalid build is marked as invalid and failed count gets updated" do
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :max_builds => 1,
    }, "ls /not/existing")
    assert_equal 0, project.failed_builds
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_FAILED, build.status
    project.reload
    assert_equal 1, project.failed_builds
  end

  test "special variable %build_dir% is available in steps" do
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :max_builds => 1,
    }, "ls -al file\nls %build_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.parts[0].output[1].stdout.include?("file")
  end

  test "special variable %project_dir% is available in steps" do
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :max_builds => 1,
    }, "ls -al file\nls %project_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert build.parts[0].output[1].stdout.include?(build.build_dir.split("/")[-1]) # build folder
  end

  test "if step produces white output then it should be set to nil" do
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :max_builds => 1,
    }, "cd %project_dir%")
    project.build!
    run_delayed_jobs()
    build = project.recent_build
    assert_equal Build::STATUS_OK, build.status
    assert_equal [], build.parts[0].output[-1].stdout
  end

  test "build #to_param includes build display name and project name" do
    project = project_with_steps({
      :name => "repo",
      :vcs_source => "test/files/repo",
      :vcs_type => "git",
      :max_builds => 2,
    }, "ls .")
    job = project.build!
    job.invoke_job
    build = project.recent_build
    assert build.to_param =~ /^#{build.id}/
    assert build.to_param.include?(project.name.to_url)
    assert build.to_param.include?(build.display_name.to_url)
  end
end
