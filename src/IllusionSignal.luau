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
		local head: Connection? = nil

		local function disconnect(self: Connection)
			if self.fn == nil then return end

			self.fn = nil

			if head == self then
				head = self.next
				return
			end

			local current = head
			while current and current.next ~= self do current = current.next end

			if current then current.next = self.next end
		end

		local Signal: Signal
		Signal = {
			Connect = function(self: Signal, fn: func): Connection
				local node: Connection = {
					fn = fn,
					next = head,
					Disconnect = disconnect,
				}

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
				local node = head
				
				while node do
					local fn = node.fn
					
					if fn ~= nil then
						fn(...)
					end
					
					node = node.next
				end
			end,

			Disconnect = function(self: Signal)
				local node = head
				
				while node do
					node.fn = nil
					local nextNode = node.next
					node.next = nil
					node = nextNode
				end
				
				head = nil
			end,
		}

		return Signal
	end
}
