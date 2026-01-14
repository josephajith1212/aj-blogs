+++
date = '2025-09-18T20:36:07-04:00'
draft = false
title = 'Docker Cheatsheet: Essential Commands for DevOps Engineers'
+++


Docker has become the foundation of modern application deployment. Whether you're containerizing applications, managing development environments, or orchestrating microservices, knowing the right Docker commands can save you hours of troubleshooting. This comprehensive guide walks you through the most useful Docker commands, starting from the basics and progressing to more advanced operations.

## Getting Started: Basic Commands

### Check Docker Installation

Before running any Docker commands, verify that Docker is installed and running on your system.

```bash
docker --version
docker info
docker run hello-world
```

The `docker --version` command displays the installed Docker version, `docker info` shows system-wide information about Docker, and `docker run hello-world` confirms that Docker daemon is running properly.

### Running Your First Container

The most fundamental Docker command is `docker run`. This command creates and starts a new container from an image.

```bash
docker run nginx
```

This pulls the nginx image from Docker Hub and runs it. The container will run in the foreground by default. To run it in the background (detached mode), use the `-d` flag:

```bash
docker run -d nginx
docker run -d --name my-nginx nginx
```

The `--name` flag assigns a custom name to your container, making it easier to manage.

### Listing and Managing Containers

See all running containers:

```bash
docker ps
docker container ls
```

To view all containers, including stopped ones:

```bash
docker ps -a
docker ps -aq
```

The `-q` flag shows only container IDs, which is useful for scripting and batch operations.

## Intermediate Operations: Working with Containers

### Starting, Stopping, and Removing Containers

Stop a running container:

```bash
docker stop <container_id>
docker kill <container_id>
```

The `stop` command sends a SIGTERM signal followed by SIGKILL after a grace period, while `kill` immediately sends SIGKILL.

Start a stopped container:

```bash
docker start <container_id>
docker restart <container_id>
```

Remove a stopped container:

```bash
docker rm <container_id>
docker rm -f <container_id>
```

The `-f` flag forces removal of running containers.

Remove all stopped containers at once:

```bash
docker container prune
docker rm $(docker ps -aq)
```

### Accessing Container Logs

View the output from a container:

```bash
docker logs <container_id>
docker logs --tail 50 <container_id>
```

Follow logs in real-time (like `tail -f`):

```bash
docker logs -f <container_id>
docker logs -f --since 10m <container_id>
```

The `--since` flag shows logs from a specific time period, and `--tail` limits the number of lines displayed.

### Executing Commands Inside Containers

Run a command inside a container:

```bash
docker exec <container_id> ls -la
docker exec <container_id> cat /etc/hosts
```

To access the container's shell interactively:

```bash
docker exec -it <container_id> /bin/bash
docker exec -it <container_id> sh
```

The `-i` flag keeps STDIN open even if not attached, and `-t` allocates a pseudo-terminal. Together, `-it` allows you to interact with the container shell just as if you were SSH'd into a remote machine.

### Inspecting Containers

Get detailed information about a container:

```bash
docker inspect <container_id>
docker inspect --format='{{.State.Status}}' <container_id>
```

The `--format` flag allows you to extract specific fields using Go templates. This outputs comprehensive JSON data about the container's configuration, network settings, volumes, and environment variables.

## Working with Images

### Pulling and Searching Images

Pull an image from Docker Hub:

```bash
docker pull ubuntu:22.04
docker pull nginx:latest
```

Search for images on Docker Hub:

```bash
docker search nginx
docker search --filter stars=100 nginx
```

### Building Your Own Images

Create a Dockerfile in your project directory:

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3
COPY . /app
WORKDIR /app
EXPOSE 8000
CMD ["python3", "app.py"]
```

Build an image from this Dockerfile:

```bash
docker build -t my-app:1.0 .
docker build -t my-app:1.0 --no-cache .
```

The `-t` flag tags the image with a name and version. The `.` specifies the build context (current directory). The `--no-cache` flag ensures a fresh build without using cached layers.

### Listing and Managing Images

View all images on your system:

```bash
docker images
docker image ls
```

View image history and layers:

```bash
docker history <image_id>
```

Remove an image:

```bash
docker rmi <image_id>
docker image rm <image_id>
```

Remove all unused images:

```bash
docker image prune
docker image prune -a
```

The `-a` flag removes all unused images, not just dangling ones.

### Tagging and Pushing Images

Tag an image for a registry:

```bash
docker tag my-app:1.0 username/my-app:1.0
docker tag my-app:1.0 myregistry.com/my-app:latest
```

Login to a registry:

```bash
docker login
docker login myregistry.com
```

Push an image to a registry:

```bash
docker push username/my-app:1.0
```

This allows you to store images in Docker Hub, private registries, or cloud repositories for sharing and deployment.

## Advanced Operations

### Port Mapping and Networking

Run a container and expose ports:

```bash
docker run -d -p 8080:80 nginx
docker run -d -p 127.0.0.1:8080:80 nginx
```

This maps port 8080 on your host machine to port 80 inside the container. Now, accessing `http://localhost:8080` will reach the nginx container. The second command binds only to localhost for security.

View port mappings:

```bash
docker port <container_id>
```

### Volume Mounting and Data Persistence

Mount a directory from your host machine into the container:

```bash
docker run -d -v /host/path:/container/path nginx
docker run -d -v my-volume:/data nginx
```

This creates a persistent connection. Changes made in either location are reflected in the other. Volumes are essential for data persistence and local development workflows.

Create and manage named volumes:

```bash
docker volume create my-volume
docker volume ls
docker volume inspect my-volume
docker volume rm my-volume
docker volume prune
```

Copy files between host and container:

```bash
docker cp myfile.txt <container_id>:/app/
docker cp <container_id>:/app/output.log ./
```

### Running Containers with Environment Variables

Pass environment variables to a container:

```bash
docker run -d -e DATABASE_URL=postgres://db:5432 my-app
docker run -d --env-file .env my-app
```

Use the `-e` flag for single variables or `--env-file` to load multiple variables from a file. This is crucial for configuration management without modifying the container image.

### Resource Limits and Constraints

Limit container resources:

```bash
docker run -d --memory="512m" --cpus="1.5" nginx
docker run -d --memory="1g" --memory-swap="2g" nginx
```

These flags prevent containers from consuming all system resources.

### Monitoring Container Performance

View real-time resource usage statistics:

```bash
docker stats
docker stats <container_id>
docker stats --no-stream
```

The `docker stats` command shows CPU, memory, network I/O, and disk I/O for running containers. The `--no-stream` flag displays a single snapshot instead of continuous updates.

Display running processes inside a container:

```bash
docker top <container_id>
docker top <container_id> aux
```

This shows process information similar to the Linux `top` command, but specific to the container.

### Inspecting Filesystem Changes

View filesystem changes in a container:

```bash
docker diff <container_id>
```

This command shows files and directories that have been added (A), modified (C), or deleted (D) since the container was created. It's invaluable for debugging and understanding what changes occurred during runtime.

### Saving and Loading Images

Save an image to a tar archive:

```bash
docker save -o myimage.tar my-app:1.0
docker save my-app:1.0 > myimage.tar
```

Load an image from a tar archive:

```bash
docker load -i myimage.tar
docker load < myimage.tar
```

The `save` and `load` commands preserve the entire image with all layers, tags, and metadata.

### Exporting and Importing Containers

Export a container's filesystem:

```bash
docker export <container_id> -o mycontainer.tar
docker export <container_id> > mycontainer.tar
```

Import a container filesystem as an image:

```bash
docker import mycontainer.tar my-new-image:1.0
cat mycontainer.tar | docker import - my-new-image:1.0
```

Unlike `save`/`load`, the `export`/`import` commands flatten the container into a single layer without history or metadata.

### Creating Images from Containers

Commit changes in a container to a new image:

```bash
docker commit <container_id> my-new-image:1.0
docker commit -m "Added nginx config" -a "John Doe" <container_id> my-new-image:1.0
```

The `-m` flag adds a commit message, and `-a` specifies the author. This is useful for creating images from modified containers, though Dockerfiles are preferred for reproducibility.

### Docker Networking

List available networks:

```bash
docker network ls
```

Create a custom network:

```bash
docker network create my-network
docker network create --driver bridge --subnet 192.168.1.0/24 my-network
```

Connect and disconnect containers from networks:

```bash
docker network connect my-network <container_id>
docker network disconnect my-network <container_id>
```

Inspect network details:

```bash
docker network inspect my-network
```

Remove networks:

```bash
docker network rm my-network
docker network prune
```

Run containers on specific networks:

```bash
docker run -d --network my-network --name web nginx
docker run -d --network my-network --name db postgres
```

Containers on the same custom network can communicate using container names as hostnames.

### Docker Compose for Multi-Container Applications

For applications requiring multiple services, Docker Compose simplifies orchestration. Create a `docker-compose.yml`:

```yaml
version: '3'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    networks:
      - app-network
    depends_on:
      - db
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: secret
    networks:
      - app-network
    volumes:
      - db-data:/var/lib/postgresql/data
networks:
  app-network:
volumes:
  db-data:
```

Essential Docker Compose commands:

```bash
docker-compose up -d
docker-compose down
docker-compose ps
docker-compose logs -f
docker-compose exec web bash
docker-compose build
docker-compose restart
docker-compose up --scale web=3
```

## System Maintenance and Cleanup

### Cleaning Up Resources

Docker can quickly consume disk space. Clean up unused resources:

```bash
docker system prune
docker system prune -a
docker system prune -a --volumes
```

The first command removes all stopped containers, unused networks, and dangling images. The `-a` flag also removes unused images, and `--volumes` removes unused volumes.

View Docker disk usage:

```bash
docker system df
docker system df -v
```

Remove specific resource types:

```bash
docker container prune
docker image prune
docker volume prune
docker network prune
```

### Pausing and Unpausing Containers

Pause all processes in a container:

```bash
docker pause <container_id>
docker unpause <container_id>
```

This freezes the container without stopping it, useful for temporary resource management.

### Renaming Containers

Rename a container:

```bash
docker rename old-name new-name
```

### Viewing Events

Monitor Docker daemon events in real-time:

```bash
docker events
docker events --since 1h
docker events --filter type=container
```

This displays real-time information about container lifecycle events, network changes, and image operations.

### Waiting for Container Exit

Block until a container stops and print its exit code:

```bash
docker wait <container_id>
```

This is useful in scripts where you need to wait for a container to complete before proceeding.

## Quick Reference Table

| Command Category | Common Commands |
|-----------------|-----------------|
| **Container Lifecycle** | `docker run`, `docker start`, `docker stop`, `docker restart`, `docker kill`, `docker rm` |
| **Container Information** | `docker ps`, `docker logs`, `docker top`, `docker stats`, `docker inspect`, `docker diff` |
| **Image Management** | `docker build`, `docker pull`, `docker push`, `docker images`, `docker rmi`, `docker tag` |
| **Data Management** | `docker volume create`, `docker volume ls`, `docker cp`, `docker commit` |
| **Networking** | `docker network create`, `docker network connect`, `docker network ls`, `docker network inspect` |
| **System Maintenance** | `docker system prune`, `docker system df`, `docker events` |
| **Import/Export** | `docker save`, `docker load`, `docker export`, `docker import` |

## Conclusion

Docker commands follow a logical progression from basic container management to advanced multi-container orchestration. Mastering these commands—from `docker run` and `docker ps` for everyday operations to `docker exec`, `docker stats`, and `docker network` for complex workflows—will significantly improve your DevOps efficiency.

Start with the basic commands like running and listing containers, gradually incorporate intermediate operations such as volume mounting and port mapping into your workflow, and progressively explore advanced features like networking, resource monitoring, and Docker Compose as your needs grow. Understanding commands like `docker diff` for filesystem inspection, `docker top` for process monitoring, and `docker save`/`docker load` for image portability will give you powerful debugging and deployment capabilities.

Remember, the Docker documentation and `docker <command> --help` are always available when you need quick reference material. With this comprehensive cheatsheet at your disposal, you're well-equipped to handle containerized applications efficiently in any DevOps environment. Happy containerizing!
