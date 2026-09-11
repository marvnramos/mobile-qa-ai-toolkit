#!/usr/bin/env ruby
# frozen_string_literal: true

# Structural gate for this toolkit. Validates:
#   - every skills/*/SKILL.md: frontmatter, trigger language, required sections
#   - every rules/*.md: frontmatter (title, impact, tags) and example/why structure
#   - agents/*.md: frontmatter (name, description, tools)
#   - manifest sync: marketplace.json <-> SKILL.md versions, plugin.json <-> marketplace
#   - local links in skill docs resolve on disk
#
# Usage: ruby scripts/audit.rb    (exit 0 = clean, 1 = errors)

require "yaml"
require "json"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
REQUIRED_SKILL_SECTIONS = ["Workflow", "Examples?", "Troubleshooting"].freeze
IMPACTS = %w[CRITICAL HIGH MEDIUM LOW].freeze

errors = []
warnings = []

def rel(path) = Pathname.new(path).relative_path_from(ROOT).to_s

def split_frontmatter(path)
  lines = File.readlines(path)
  return [nil, File.read(path)] unless lines.first&.strip == "---"

  close = lines[1..].index { |l| l.strip == "---" }
  return [nil, File.read(path)] unless close

  [YAML.safe_load(lines[1..close].join, permitted_classes: [], aliases: false),
   (lines[(close + 2)..] || []).join]
end

# ── Skills ────────────────────────────────────────────────────
skills = {}
Dir.glob(ROOT.join("skills/*/SKILL.md").to_s).sort.each do |path|
  fm, body = split_frontmatter(path)
  if fm.nil?
    errors << "#{rel(path)}: missing or unterminated YAML frontmatter"
    next
  end

  folder = File.basename(File.dirname(path))
  name = fm["name"].to_s
  description = fm["description"].to_s

  errors << "#{rel(path)}: `name` must match folder `#{folder}`" unless name == folder
  errors << "#{rel(path)}: `name` must be kebab-case" unless name.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
  errors << "#{rel(path)}: `description` is required" if description.empty?
  errors << "#{rel(path)}: `description` exceeds 1024 chars (#{description.length})" if description.length > 1024
  errors << "#{rel(path)}: `description` must contain trigger language (\"Use when …\")" unless description.match?(/\buse when\b/i)
  warnings << "#{rel(path)}: no `allowed-tools` declared" unless fm.key?("allowed-tools")

  REQUIRED_SKILL_SECTIONS.each do |section|
    errors << "#{rel(path)}: missing `## #{section.delete("?")}` section" unless body.match?(/^##+\s+#{section}\b/i)
  end
  ["- Error:", "- Cause:", "- Solution:", "Expected behavior:"].each do |marker|
    errors << "#{rel(path)}: Troubleshooting must use the `#{marker}` format" unless body.include?(marker)
  end

  # local links must resolve
  body.gsub(/```.*?```/m, "").scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
    link = target.split("#").first.to_s
    next if link.empty? || link.match?(%r{\Ahttps?://|\Amailto:})

    errors << "#{rel(path)}: broken local link `#{target}`" unless File.exist?(File.expand_path(link, File.dirname(path)))
  end

  skills[name] = { version: fm.dig("metadata", "version"), path: }

  # ── Rules of this skill ─────────────────────────────────────
  Dir.glob(File.join(File.dirname(path), "rules/*.md")).sort.each do |rule|
    next if File.basename(rule) == "_sections.md"

    rfm, rbody = split_frontmatter(rule)
    if rfm.nil?
      errors << "#{rel(rule)}: rule needs YAML frontmatter (title, impact, tags)"
      next
    end
    errors << "#{rel(rule)}: rule needs a `title`" if rfm["title"].to_s.empty?
    errors << "#{rel(rule)}: `impact` must be one of #{IMPACTS.join(", ")}" unless IMPACTS.include?(rfm["impact"].to_s)
    errors << "#{rel(rule)}: rule needs `tags`" unless rfm["tags"].is_a?(Array) && !rfm["tags"].empty?
    errors << "#{rel(rule)}: rule needs an **Incorrect** example" unless rbody.match?(/\*\*Incorrect/i)
    errors << "#{rel(rule)}: rule needs a **Correct** example" unless rbody.match?(/\*\*Correct/i)
    errors << "#{rel(rule)}: rule needs a **Why it matters** section" unless rbody.match?(/\*\*Why it matters/i)
  end

  sections = File.join(File.dirname(path), "rules/_sections.md")
  errors << "#{rel(path)}: rules/ present without `_sections.md`" if Dir.exist?(File.join(File.dirname(path), "rules")) && !File.exist?(sections)
end

errors << "no skills found under skills/*/SKILL.md" if skills.empty?

# ── Agents ────────────────────────────────────────────────────
Dir.glob(ROOT.join("agents/*.md").to_s).sort.each do |path|
  fm, = split_frontmatter(path)
  if fm.nil?
    errors << "#{rel(path)}: agent needs YAML frontmatter (name, description, tools)"
    next
  end
  %w[name description tools].each do |key|
    errors << "#{rel(path)}: agent frontmatter missing `#{key}`" if fm[key].to_s.empty?
  end
  folder_name = File.basename(path, ".md")
  errors << "#{rel(path)}: agent `name` must match filename" unless fm["name"].to_s == folder_name
end

# ── Mirrors ───────────────────────────────────────────────────
# The plugin loads agents/ and commands/ from the repo root; a skills-CLI install
# ships only skills/, so the same files are mirrored into the skill's assets.
# They must stay byte-identical — this gate is what makes the duplication safe.
MIRRORS = {
  "agents/qa-mobile-emulator.md" => "skills/qa-mobile-emulator/assets/agents/qa-mobile-emulator.md",
  "commands/qa-mobile.md" => "skills/qa-mobile-emulator/assets/commands/qa-mobile.md"
}.freeze

MIRRORS.each do |canonical, copy|
  a = ROOT.join(canonical)
  b = ROOT.join(copy)
  next errors << "#{copy}: mirror of #{canonical} is missing" unless File.exist?(b)
  next errors << "#{canonical}: missing" unless File.exist?(a)

  errors << "#{copy}: drifted from #{canonical} — copy it over" unless File.read(a) == File.read(b)
end

installer = ROOT.join("skills/qa-mobile-emulator/assets/install.sh")
errors << "skills/qa-mobile-emulator/assets/install.sh: missing" unless File.exist?(installer)
errors << "scripts/install.sh: must delegate to the skill's installer" unless File.exist?(ROOT.join("scripts/install.sh")) &&
  File.read(ROOT.join("scripts/install.sh")).include?("skills/qa-mobile-emulator/assets/install.sh")

# ── Manifests ─────────────────────────────────────────────────
catalog = JSON.parse(File.read(ROOT.join("marketplace.json"))) rescue nil
if catalog.nil?
  errors << "marketplace.json: missing or invalid JSON"
else
  listed = (catalog["skills"] || []).to_h { |s| [s["name"], s] }
  skills.each do |name, data|
    entry = listed[name]
    next errors << "marketplace.json: no entry for skill `#{name}`" if entry.nil?
    next warnings << "#{rel(data[:path])}: no metadata.version set" if data[:version].nil?

    if entry["version"].to_s != data[:version].to_s
      errors << "marketplace.json: `#{name}` version #{entry["version"]} != SKILL.md #{data[:version]}"
    end
    source = ROOT.join(entry["source"].to_s, "SKILL.md")
    errors << "marketplace.json: `#{name}` source path does not exist" unless File.exist?(source)
  end
  (listed.keys - skills.keys).each { |name| errors << "marketplace.json: entry `#{name}` has no skill on disk" }
end

plugin = JSON.parse(File.read(ROOT.join(".claude-plugin/plugin.json"))) rescue nil
market = JSON.parse(File.read(ROOT.join(".claude-plugin/marketplace.json"))) rescue nil
errors << ".claude-plugin/plugin.json: missing or invalid JSON" if plugin.nil?
errors << ".claude-plugin/marketplace.json: missing or invalid JSON" if market.nil?
if plugin && market
  entry = (market["plugins"] || []).find { |p| p["name"] == plugin["name"] }
  if entry.nil?
    errors << ".claude-plugin/marketplace.json: does not list plugin `#{plugin["name"]}`"
  elsif entry["version"].to_s != plugin["version"].to_s
    errors << ".claude-plugin: marketplace version #{entry["version"]} != plugin.json #{plugin["version"]}"
  end
end

# ── Report ────────────────────────────────────────────────────
puts "Skills audited:  #{skills.size}"
puts "Agents audited:  #{Dir.glob(ROOT.join("agents/*.md").to_s).size}"
warnings.each { |w| puts "[WARN]  #{w}" }
errors.each   { |e| puts "[ERROR] #{e}" }
puts "Summary: errors=#{errors.size}, warnings=#{warnings.size}"
exit(errors.empty? ? 0 : 1)
