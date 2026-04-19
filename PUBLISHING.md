# Publishing to hex.pm - Instructions

## ✅ Package is Ready for Publication

All files have been configured and committed. The package is ready to publish with:

### Quick Publish

```bash
cd /home/nagieeb/projects/ash_form_builder
mix hex.publish
```

You will be prompted to:
1. Log in to hex.pm (or create an account at https://hex.pm)
2. Confirm publication
3. Enter your API key if not already authenticated

### Alternative: Non-Interactive Publish

If you have an API key:

```bash
mix hex.publish --replace
```

Or with API key environment variable:

```bash
export HEX_API_KEY=your_api_key_here
mix hex.publish --yes
```

---

## 📦 Package Details

- **Name**: ash_form_builder
- **Version**: 0.1.0
- **Status**: EXPERIMENTAL
- **License**: MIT
- **Maintainer**: Ahmed Al-Nagieeb

### Description

```
⚠️  EXPERIMENTAL - Use at Your Own Risk ⚠️

Auto-generates Phoenix LiveView forms from Ash Framework resources. 
Features: auto-inference, searchable/creatable combobox, nested forms, themes.

EXPERIMENTAL: API may change. Use at your own risk.
```

### Dependencies

Runtime:
- spark ~> 2.0
- ash ~> 3.0
- ash_phoenix ~> 2.0
- phoenix_live_view ~> 1.0
- phoenix ~> 1.7
- phoenix_html ~> 4.0
- mishka_chelekom ~> 0.0.8

Dev:
- ex_doc ~> 0.31
- ecto_sql ~> 3.10
- postgrex >= 0.0.0

### Files Included

```
lib/                          # Source code
mix.exs                       # Package configuration
README.md                     # Documentation with experimental warning
LICENSE                       # MIT License
CHANGELOG.md                  # Version history and known issues
guides/                       # Integration guides
example_usage.ex              # Reference documentation
```

---

## 🔗 Links

After publication, the package will be available at:

- **hex.pm**: https://hex.pm/packages/ash_form_builder
- **Docs**: https://hexdocs.pm/ash_form_builder
- **GitHub**: https://github.com/nagieeb0/ash_form_builder

---

## 📝 Post-Publication Steps

1. **Verify Publication**
   ```bash
   mix hex.info ash_form_builder
   ```

2. **Generate Documentation**
   ```bash
   mix docs
   ```

3. **Update GitHub Description**
   - Add hex.pm badge to README
   - Update installation instructions

4. **Announce Release**
   - Share on Elixir forums
   - Post in Ash Framework Discord/Slack
   - Tweet about the release

---

## ⚠️ Important Notes

### Experimental Status

This is version **0.1.0** - an experimental release. Users should:

- Pin to exact version: `{:ash_form_builder, "== 0.1.0"}`
- Test thoroughly before production use
- Monitor for breaking changes
- Report issues on GitHub

### Next Steps for 0.2.0

Planned improvements:
- Better creatable value extraction
- Loading states for async operations
- Inline error handling
- i18n support
- More comprehensive tests

### Roadmap to 1.0

See CHANGELOG.md for the complete roadmap to stable release.

---

## 🆘 Troubleshooting

### "Package description is too long"

Already fixed - description is now under 300 characters.

### "Authentication failed"

1. Create account at https://hex.pm
2. Generate API key at https://hex.pm/settings/api
3. Run: `mix hex.user auth`
4. Enter API key when prompted

### "Dependency resolution failed"

Run: `mix hex.audit` to check for issues

### "Build failed"

Ensure all dependencies are fetched:
```bash
mix deps.get
mix deps.compile
```

---

## ✨ Success Criteria

After successful publication:

- ✅ Package visible on hex.pm
- ✅ Documentation generated on hexdocs.pm
- ✅ Can install with `mix hex.info ash_form_builder`
- ✅ All links working (GitHub, Ash Framework)
- ✅ Experimental warning clearly visible

---

**Good luck with the publication! 🚀**
