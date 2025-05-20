return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    strategies = {
      chat = {
        adapter = 'gemini',
      },
      inline = {
        adapter = 'gemini',
      },
    },
    adapters = {
    gemini = function()
      return require('codecompanion.adapters').extend('gemini', {
        schema = {
          model = {
            default = 'gemini-2.5-pro-preview-05-06',
          },
        },
        env = {
          api_key = 'cmd:op read op://Private/ggxinrutdu7ozhhk4hkuoumgc4/password --no-newline'',
        },
      })
    end,
      anthropic = function()
        return require('codecompanion.adapters').extend('anthropic', {
          env = {
            api_key = 'cmd:op read op://Private/cal3t3a46hhk4xb3o4nhaq5ogy/password --no-newline',
          },
        })
      end,
    },
  },
}
