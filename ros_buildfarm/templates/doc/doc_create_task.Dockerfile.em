# generated from @template_name

FROM ubuntu:@os_code_name
MAINTAINER Dirk Thomas dthomas+buildfarm@@osrfoundation.org

VOLUME ["/var/cache/apt/archives"]

ENV DEBIAN_FRONTEND noninteractive

@(TEMPLATE(
    'snippet/setup_locale.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
    timezone=timezone,
))@

RUN useradd -u @uid -m buildfarm

@(TEMPLATE(
    'snippet/add_distribution_repositories.Dockerfile.em',
    distribution_repository_keys=distribution_repository_keys,
    distribution_repository_urls=distribution_repository_urls,
    os_code_name=os_code_name,
    add_source=False,
))@

@(TEMPLATE(
    'snippet/add_wrapper_scripts.Dockerfile.em',
    wrapper_scripts=wrapper_scripts,
))@

# automatic invalidation once every day
RUN echo "@today_str"

@(TEMPLATE(
    'snippet/install_python3.Dockerfile.em',
    os_name=os_name,
    os_code_name=os_code_name,
))@

RUN python3 -u /tmp/wrapper_scripts/apt-get.py update-and-install -q -y git mercurial python3-apt python3-catkin-pkg python3-empy python3-rosdep python3-rosdistro subversion

# always invalidate to actually have the latest apt and rosdep state
RUN echo "@now_str"
RUN python3 -u /tmp/wrapper_scripts/apt-get.py update

ENV ROSDISTRO_INDEX_URL @rosdistro_index_url
RUN rosdep init

USER buildfarm

ENTRYPOINT ["sh", "-c"]
@{
cmds = [
    'rosdep update',

    'PYTHONPATH=/tmp/ros_buildfarm:$PYTHONPATH python3 -u' + \
    ' /tmp/ros_buildfarm/scripts/doc/create_doc_task_generator.py' + \
    ' ' + config_url + \
    ' --rosdistro-name ' + rosdistro_name + \
    ' ' + doc_build_name + \
    ' --workspace-root /tmp/catkin_workspace' + \
    ' --rosdoc-lite-dir /tmp/rosdoc_lite' + \
    ' --catkin-sphinx-dir /tmp/catkin-sphinx' + \
    ' --rosdoc-index-dir /tmp/rosdoc_index' + \
    ' ' + repository_name + \
    ' --os-name ' + os_name + \
    ' --os-code-name ' + os_code_name + \
    ' --arch ' + arch + \
    ' --vcs-info "%s"' % vcs_info + \
    ' --distribution-repository-urls ' + ' '.join(distribution_repository_urls) + \
    ' --distribution-repository-key-files ' + ' ' .join(['/tmp/keys/%d.key' % i for i in range(len(distribution_repository_keys))]) + \
    (' --force' if force else '') + \
    ' --output-dir /tmp/generated_documentation' + \
    ' --dockerfile-dir /tmp/docker_doc',
]
}@
CMD ["@(' && '.join([c.replace('"', '\\"') for c in cmds]))"]
