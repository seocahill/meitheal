require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  # Guards the contract the MCP initializer relies on: tools live under
  # ApplicationTool so `server.register_tools(*ApplicationTool.descendants)`
  # registers them, and each advertises a name for the client.
  test "todo tools are registered as named ApplicationTool descendants" do
    [ ListTodosTool, DeleteTodoTool, PurgeNoisyTodosTool ].each do |tool|
      assert_includes ApplicationTool.descendants, tool
      assert tool.tool_name.present?, "#{tool} must declare a tool_name"
    end
  end
end
