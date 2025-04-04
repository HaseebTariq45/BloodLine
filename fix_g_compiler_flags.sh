#!/bin/bash

echo "========== Fixing problematic compiler flags for arm64-ios build ==========="

# Check for problematic compiler flags in project.pbxproj
echo "Checking for problematic -G flags in project.pbxproj..."
if grep -q -- "-G" ios/Runner.xcodeproj/project.pbxproj; then
  echo "Found -G flags in project.pbxproj, removing them..."
  sed -i '' 's/-G[^\ ]*//g' ios/Runner.xcodeproj/project.pbxproj
  echo "Removed -G flags from project.pbxproj"
else
  echo "No -G flags found in project.pbxproj"
fi

# Check for OTHER_CFLAGS in xcconfig files
echo "Checking for problematic flags in xcconfig files..."
find ios -name "*.xcconfig" -type f -exec grep -l "OTHER_CFLAGS" {} \; | while read -r file; do
  echo "Checking $file for -G flags..."
  if grep -q -- "-G" "$file"; then
    echo "Found -G flags in $file, removing them..."
    sed -i '' 's/-G[^\ ]*//g' "$file"
    echo "Removed -G flags from $file"
  fi
done

# Check for flags in Generated.xcconfig
GEN_XCCONFIG="ios/Flutter/Generated.xcconfig"
if [ -f "$GEN_XCCONFIG" ]; then
  echo "Checking Generated.xcconfig for -G flags..."
  if grep -q -- "-G" "$GEN_XCCONFIG"; then
    echo "Found -G flags in Generated.xcconfig, removing them..."
    sed -i '' 's/-G[^\ ]*//g' "$GEN_XCCONFIG"
    echo "Removed -G flags from Generated.xcconfig"
  else
    echo "No -G flags found in Generated.xcconfig"
  fi
else
  echo "Generated.xcconfig not found, will be created on next Flutter build"
fi

# Add explicit patch to override any specific pod's compiler flags that might have -G
echo "Creating post-install hook patch to fix any pods with -G flags..."
cat > ios/fix_compiler_flags.rb << 'EOL'
# Fix compiler flags for pods during post_install
def fix_pod_compiler_flags(installer)
  puts "Fixing compiler flags in pods..."
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['OTHER_CFLAGS']
        puts "Fixing OTHER_CFLAGS for #{target.name} in #{config.name} configuration"
        config.build_settings['OTHER_CFLAGS'] = config.build_settings['OTHER_CFLAGS'].reject { |flag| flag.include?('-G') }
      end
      
      # Also directly remove any -G flags from all other build settings
      config.build_settings.each do |key, value|
        if value.is_a?(String) && value.include?('-G')
          puts "Fixing #{key} for #{target.name} in #{config.name} configuration"
          config.build_settings[key] = value.gsub(/-G[^ ]*/, '')
        elsif value.is_a?(Array)
          g_flags = value.select { |v| v.is_a?(String) && v.include?('-G') }
          unless g_flags.empty?
            puts "Fixing #{key} array for #{target.name} in #{config.name} configuration"
            config.build_settings[key] = value.reject { |v| v.is_a?(String) && v.include?('-G') }
          end
        end
      end
    end
  end
end
EOL

echo "Adding require statement to Podfile for the fix_compiler_flags.rb script..."
if ! grep -q "require './fix_compiler_flags.rb'" ios/Podfile; then
  # Add require statement at the top of the Podfile
  sed -i '' '1s/^/require ".\/fix_compiler_flags.rb"\n/' ios/Podfile
  echo "Added require statement to Podfile"
else
  echo "require statement already exists in Podfile"
fi

# Add call to fix_pod_compiler_flags in post_install if it doesn't exist
if ! grep -q "fix_pod_compiler_flags" ios/Podfile; then
  # Add fix_pod_compiler_flags to post_install
  sed -i '' '/post_install do |installer|/a\
  fix_pod_compiler_flags(installer)
' ios/Podfile
  echo "Added fix_pod_compiler_flags call to post_install"
else
  echo "fix_pod_compiler_flags call already exists in post_install"
fi

echo "Running pod install to apply changes..."
cd ios
pod install
cd ..

echo "========== Fixed compiler flags for arm64-ios build ===========" 