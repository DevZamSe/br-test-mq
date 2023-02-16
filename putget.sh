# Run the amqsput and amqsget samples in sequence, extracting the MsgId
# from the PUT operation and using it to retrieve the message in the GET sample
message=$1
go run amqsput.go SFISERS500A.REQ * ${message} | tee /tmp/putget.out
id=`grep MsgId /tmp/putget.out | cut -d: -f2`

if [ "${id}" != "" ]
then
  echo "Getting MsgId" ${id}
  go run amqsget.go SFISERS500A.RESP * ${id}
fi
