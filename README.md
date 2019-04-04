# demo-docker-workflow-issue

Minimal reproduction of issue with Jenkins docker-workflow-plugin

We have a use-case for the docker-workflow-plugin which involves a slightly peculiar Jenkins agent setup. We use the Jenkins docker plugin (https://github.com/jenkinsci/docker-plugin) as the default build cloud for Jenkins agents to spin up a containerized Jenkins agent for each build. We use the "Launch via SSH" method (https://wiki.jenkins.io/display/JENKINS/Docker+Plugin) to connect to the docker-based slaves. We also install docker-in-docker in the slave container, so that we can run docker commands and small docker builds within the build workspace. The Dockerfiles in this repo are a stripped-down version of the image we would use for this purpose.


When trying to use the `dockerfile` agent parameters (https://jenkins.io/doc/book/pipeline/syntax/#agent-parameters) in combination with these agents, the getContainerId implementation in https://github.com/jenkinsci/docker-workflow-plugin/blob/master/src/main/java/org/jenkinsci/plugins/docker/workflow/client/ControlGroup.java misses the mark and gives an error that looks like:

```
Unexpected cgroup syntax /docker/def365fbd3d6eccd4fc0cd3c30bc18bd877c3127b3f8c01246892da1e3349999/docker/def365fbd3d6eccd4fc0cd3c30bc18bd877c3127b3f8c01246892da1e3349999/user/jenkins/0
```

The source of the `/user/jenkins/0` bit at the end is the SSH connection mechanism, as you can see if you run the `build.sh` script in this repo. Commands executed within the container have the normal docker-in-docker type cgroup hierarchies:

```
+ cat /proc/self/cgroup
13:name=systemd:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
12:pids:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
11:hugetlb:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
10:net_prio:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
9:perf_event:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
8:net_cls:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
7:freezer:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
6:devices:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
5:memory:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
4:blkio:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
3:cpuacct:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
2:cpu:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
1:cpuset:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
```

When running docker commands through the SSH connection, some of the hierarchies get longer

```
+ cat /proc/self/cgroup
13:name=systemd:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/user/jenkins/0
12:pids:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
11:hugetlb:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
10:net_prio:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
9:perf_event:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
8:net_cls:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
7:freezer:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/user/jenkins/0
6:devices:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
5:memory:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b/user/jenkins/0
4:blkio:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
3:cpuacct:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
2:cpu:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
1:cpuset:/docker/86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
86912ae1587e8c8ff76be18651fed9779fa1d85cb201311784bdcbd473c0143b
```

