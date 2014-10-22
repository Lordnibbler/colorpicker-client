import subprocess
import time

host = "yahoo.com"

while True:
	ping = subprocess.Popen(
    		["ping", "-c", "2", host],
   		 stdout = subprocess.PIPE,
   		 stderr = subprocess.PIPE
	)

	out, error = ping.communicate()


	print out
	import re
        matcher = re.search(r"(\d) packets transmitted, (\d) received",out)
	if(matcher):
		print matcher.group(1)
		print matcher.group(2)

		sent = matcher.group(1)
		received = matcher.group(2)

		if(sent == received):
			time_now = time.asctime(time.localtime())
			print time_now
			f = open('last_ping.txt','w')
			f.write(time_now)
			f.close()

	time.sleep(10)
