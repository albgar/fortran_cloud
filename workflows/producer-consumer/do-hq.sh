hq worker start --cpus 1 --resource "proxy=sum(1)" &
hq worker start --cpus 1 --resource "consumer=sum(1)" &
hq worker start --cpus 1 --resource "consumer=sum(1)" &
hq worker start --cpus 1 --resource "consumer=sum(1)" &
hq worker start --cpus 1 --resource "consumer=sum(1)" &
hq worker start --cpus 1 --resource "consumer=sum(1)" &
hq worker start --cpus 1 --resource "producer=sum(1)" &

# Make sure this is the first job to run
hq submit --cpus 1 --resource "proxy=1" ./test_proxy 
sleep 2

hq submit --cpus 1 --resource "consumer=1" ./test_recv black 
hq submit --cpus 1 --resource "consumer=1" ./test_recv white 
hq submit --cpus 1 --resource "consumer=1" ./test_recv red 
hq submit --cpus 1 --resource "consumer=1" ./test_recv blue 
hq submit --cpus 1 --resource "consumer=1" ./test_recv green

hq submit --cpus 1 --resource "producer=1" ./test &

