docker run -d -i --name druid -p 3000:8082 -p 3001:8081 --link cass1:cass1 druid/cluster
