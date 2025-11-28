--!strict
--[[
  /////////////////////
 // Illusion Signal // 
/////////////////////
]]

type func = (...any) -> ()

type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

type Signal = {
	Connect: (self: Signal, fn: func) -> Connection,
	Once: (self: Signal, fn: func) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Wait: (self: Signal) -> ...any,
	DisconnectAll: (self: Signal) -> (),
}

type Node = {
	fn: func,
	next: Node?,
}

return {
	new = function(): Signal
		local head: Node? = nil

		local function createConnection(node: Node, prev: Node?): Connection
			local connected = true

			local conn: Connection = {
				Connected = true,
				Disconnect = function(self)
					if not connected then return end
					connected = false
					self.Connected = false

					if head == node then
						head = node.next
						return
					end

					local current = head
					while current and current.next ~= node do
						current = current.next
					end

					if current then
						current.next = node.next
					end
				end,
			}

			return conn
		end

		local Signal: Signal = {
			Connect = function(self: Signal, fn: func): Connection
				local node: Node = {
					fn = fn,
					next = head,
				}

				head = node
				return createConnection(node)
			end,

			Once = function(self: Signal, fn: func): Connection
				local fired = false
				local conn: Connection

				conn = self:Connect(function(...)
					if fired then return end
					fired = true
					conn:Disconnect()
					fn(...)
				end)

				return conn
			end,

			Wait = function(self: Signal): ...any
				local thread = coroutine.running()
				local conn: Connection
				local args: {any}? = nil

				conn = self:Connect(function(...)
					conn:Disconnect()
					args = table.pack(...)
					task.spawn(thread)
				end)

				coroutine.yield()
				return table.unpack(args or {})
			end,

			Fire = function(self: Signal, ...: any)
				local node = head
				while node do
					node.fn(...)
					node = node.next
				end
			end,

			DisconnectAll = function(self: Signal)
				head = nil
			end,
		}

		return Signal
	end
}
