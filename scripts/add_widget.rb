# Injects the WeeklyWidget Live Activity extension and the LiveTimer Capacitor
# plugin into the Capacitor-generated Xcode project. Run from the repo root
# AFTER `npx cap sync ios` and after the native sources have been copied:
#   ios/App/WeeklyWidget/  (widget UI + Info.plist)
#   ios/App/Shared/        (attributes + intent, compiled into BOTH targets)
#   ios/App/App/LiveTimer/ (Capacitor plugin, app target only)
require 'xcodeproj'

project_path = 'ios/App/App.xcodeproj'
proj = Xcodeproj::Project.open(project_path)

app = proj.targets.find { |t| t.name == 'App' }
raise 'App target not found' unless app

mv = ENV['MV'] || '1.1.1'
build_num = ENV['GITHUB_RUN_NUMBER'] || '1'

# ── Widget extension target ──
widget = proj.new_target(:app_extension, 'WeeklyWidget', :ios, '17.0')
widget.build_configurations.each do |c|
  bs = c.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.chimpinski.weeklyfocus.widget'
  bs['INFOPLIST_FILE'] = 'WeeklyWidget/Info.plist'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['MARKETING_VERSION'] = mv
  bs['CURRENT_PROJECT_VERSION'] = build_num
  bs['CODE_SIGNING_ALLOWED'] = 'NO'
  bs['CODE_SIGNING_REQUIRED'] = 'NO'
  bs['CODE_SIGN_IDENTITY'] = ''
  bs['SKIP_INSTALL'] = 'YES'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

# ── File groups ──
widget_group = proj.main_group.new_group('WeeklyWidget', 'WeeklyWidget')
%w[WeeklyWidgetBundle.swift FocusLiveActivity.swift].each do |f|
  ref = widget_group.new_reference(f)
  widget.add_file_references([ref])
end
widget_group.new_reference('Info.plist') # visible in project, not compiled

shared_group = proj.main_group.new_group('Shared', 'Shared')
%w[FocusActivityAttributes.swift TimerControlIntent.swift].each do |f|
  ref = shared_group.new_reference(f)
  widget.add_file_references([ref])
  app.add_file_references([ref])
end

plugin_group = proj.main_group.new_group('LiveTimer', 'App/LiveTimer')
%w[LiveTimerPlugin.swift LiveTimerPlugin.m].each do |f|
  ref = plugin_group.new_reference(f)
  app.add_file_references([ref])
end

# ── Embed the extension into the app ──
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(widget.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

proj.save
puts "Added WeeklyWidget extension and LiveTimer plugin to #{project_path}"
puts "  widget files: #{widget.source_build_phase.files_references.map(&:path).inspect}"
puts "  app now compiles: #{app.source_build_phase.files_references.map(&:path).inspect}"
