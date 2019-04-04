#! /bin/bash -e

# Demonstrate issue with docker-workflow-plugin when using docker-based slaves connected with the SSH Slaves plugin

docker_build_logfile="dockerbuild.log"
static_ssh_port=2222

build_cleanup() {
	docker rm -fv "$container_id" || true
}

runTest() {
	trap "build_cleanup && exit 1" SIGINT
    trap "build_cleanup" EXIT
	set -e

	tag="$1"
	image="demo-jenkins-slave:${tag}"
	echo "Building image ${image} ..."
	docker build -t "$image" -f "Dockerfile.${tag}" . > "$docker_build_logfile"
	# Check cgroup mounts within container
	echo "Describe cgroup mounts using docker exec"
	container_id=$(docker run -d --privileged -p "$static_ssh_port":22 "$image")
	docker exec -u jenkins "${container_id}" cat /proc/self/cgroup
	echo "Describe cgroup mounts by SSH into the container"
	ssh -p "$static_ssh_port" jenkins@localhost cat /proc/self/cgroup
	docker rm -f "$container_id"

}

runTest stretch
runTest trusty
runTest xenial
runTest bionic
