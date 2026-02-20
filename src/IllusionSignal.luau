--!strict
--!optimize 2
--!native

--[[
  /////////////////////
 // Illusion Signal // 
/////////////////////
]]

type func = (...any) -> ()

export type Connection = {
	fn: func?,
	next: Connection?,
	prev: Connection?,
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, fn: func) -> Connection,
	Once: (self: Signal, fn: func) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Wait: (self: Signal) -> ...any,
	Disconnect: (self: Signal) -> (),
}

return {
	new = function(): Signal
		local firing = false
		local head: Connection? = nil

		local function disconnect(self: Connection)
			if not self.Connected then return end
			
			self.Connected = false
			self.fn = nil

			local prev = self.prev
			local next = self.next

			if prev then
				prev.next = next
			else
				head = next
			end

			if next then
				next.prev = prev
			end

			self.next = nil
			self.prev = nil
		end

		local Signal: Signal
		Signal = {
			Connect = function(self: Signal, fn: func): Connection
				local node: Connection = {
					fn = fn,
					next = head,
					prev = nil,
					Connected = true,
					Disconnect = disconnect,
				}

				if head then
					head.prev = node
				end

				head = node
				return node
			end,

			Once = function(self: Signal, fn: func): Connection
				local connection: Connection

				connection = self.Connect(self, function(...)
					connection:Disconnect()
					fn(...)
				end)

				return connection
			end,

			Wait = function(self: Signal): ...any
				local thread = coroutine.running()
				local connection: Connection

				connection = self.Connect(self, function(...)
					connection:Disconnect()
					task.spawn(thread, ...)
				end)

				return coroutine.yield()
			end,

			Fire = function(self: Signal, ...: any)
				if firing then return end
				firing = true

				local node = head
				while node do
					local current = node
					node = node.next

					if current.Connected then
						local fn = current.fn
						if fn ~= nil then
							fn(...)
						end
					end
				end

				firing = false
			end,

			Disconnect = function(self: Signal)
				local node = head
				
				while node do
					node.Connected = false
					node.fn = nil
					
					local nextNode = node.next
					node.next = nil
					node.prev = nil
					
					node = nextNode
				end
				
				head = nil
			end,
		}

		return Signal
	end
}
