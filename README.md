# Brocode Server

Brocode server is the server used by [Brocode](https://github.com/AdrienDhmx/Brocode) to handle lobbies.

## How to run

You can run the server on your local machine by running /bin/brocode_server.dart: 

```shell
 dart run .\bin\brocode_server.dart
```

Or by using docker with the following commands:

First build the docker image:
```shell  
 docker build -t brocode-server .  
```  

Then you can run the image with this command (0.0.0.0 is to run on your local machine):

```shell
 docker run -p 8083:8083 -e BROCODE_SERVER_IP=0.0.0.0 brocode-server  
```

#### using docker-compose:
server listens on port 8083

```shell
 docker-compose up -d
```

down the server:

```shell
 docker-compose down
```


And now you can access the server at the distant address you specified or on your local machine at [localhost:8083](http://localhost:8080/).