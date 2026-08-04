--[[
** WARNING **

This is intended as reference code and has NOT been tested at scale.

Creators looking for production implementation that scales to high player counts may wish to consider implementing
code reservation via an external web service using HttpService.

** Code Reservation Service Module Limitations **

The Code Reservation Service Module makes codes from DataStore available in MemoryStore. Servers can reserve a
number of codes from MemoryStore and hand them out to players. Once a server is running low on codes, it will
reserve more. When a code has been handed out, it is marked as Used and never handed out again.

Single keys in a MemoryStore Sorted Map are used to hold codes, so they can be bulk read/written with a single operation.

* Order of Operations *
	1. Leader Server selects available codes and marks them as Reserved in DataStore, they can no longer be used
	2. Previously selected codes are placed into Available queue in MemoryStore
	3. Servers remove codes from Available queue, waiting to give them out
	4. Servers give out codes, placing them into the Used queue in MemoryStore
	5. Leader Server reads codes in Used queue, marks them as Used in DataStore, then removes them from Used queue

Servers which shut down go through a similar process to Used codes, instead placing codes in a Released queue.
Codes from the Released queue are marked as Available again in DataStore.

* Code Limitations *
All codes should be a uniform length. For the purposes of this README, codes are assumed to be 6 characters in length.
This allows for 308,915,776 possible codes using only lowercase letters.

* DataStore Limitations *
DataStores have a maximum value of 4MB per key. Codes in DataStore are stored in a JSON encoded dictionary with the
format "abcdef": "A". This allows for a maximum of 307,692 codes stored in DataStore.

If more codes are required to be stored, multiple code reservations can be created.

* MemoryStore Limitations *
MemoryStores have a maximum value of 32KB per key. Codes in MemoryStore are stored in a JSON encoded array, allowing
for a maximum of 3,555 codes to be stored in a single MemoryStore key.

New codes are made available to servers every 60 seconds, allowing for a global code redemption rate of 3,555 codes/minute.
If necessary, the interval can be lowered to 30 seconds (minimum recommended) allowing for 7,110 codes/minute.

The global limit for a single SortedMap is 100,000 operation units per minute. The Available queue has the most traffic,
as it is used by servers reserving codes and refilled by the leader server. At the default interval of 60s, the leader server
uses 6 operation units per minute, 2 of which are directed to the Available queue. At an interval of 30s, these numbers are
doubled. Each individual server uses up to 4 operation units per minute, 2 of which are directed at the Available queue.
At either interval, this allows for a total of just under 50,000 active servers.

Since each server reserves multiple codes at once, it is possible to have more Available codes than are able to fit into
the Used queue. For example:
	- Each server is configured to reserve 10 codes
	- Over the course of a few minutes, 500 servers each reserve 10 codes
		- Total of 5000 codes reserved by servers
		- This is possible because the Available queue will be continuously refilled
	- All codes are redeemed at once, not all codes can fit back into the Used queue

This is not an issue if it happens once or twice, since the servers will simply wait for the Used queue to clear out and
then place codes into it again. If this many codes continue to be given out, the Used queue may stay full indefinitely

When servers shut down, the codes they have currently reserved are released back to MemoryStore to be made available again.
If all servers shut down at once and there are more than 3,555 codes reserved across the servers, some codes will fail to be
released and will not be made available again.
--]]
