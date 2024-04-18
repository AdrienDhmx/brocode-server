# Brocode Server

Brocode server is the server used by [Brocode](https://github.com/AdrienDhmx/Brocode) to handle lobbies.

## How to run

The app uses docker, therefore, use this command to build the docker image:
```shell  
 docker build -t brocode-server .  
```  

Then this command to run the image:

```shell  
 docker run -p 8080:8080 brocode-server  
```  

And now you can access the server on your local machine at [localhost:8080](http://localhost:8080/).