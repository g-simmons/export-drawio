#!/usr/bin/env bats

setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    
    # Create a mock draw.io executable for testing
    mkdir -p "$TEST_DIR/Applications/draw.io.app/Contents/MacOS"

    cat > "$TEST_DIR/Applications/draw.io.app/Contents/MacOS/draw.io" <<'EOF'
#!/bin/bash
echo "Mock draw.io called with args: $@"
# Simulate XML export
if [[ "$*" == *"--format xml"* ]]; then
    filename=$(echo "$@" | grep -o '[^ ]*\.drawio' | sed 's/\.drawio$/.xml/')
    echo '<diagram name="Page1"></diagram><diagram name="Page2"></diagram>' > "$filename"
fi
EOF

    chmod +x "$TEST_DIR/Applications/draw.io.app/Contents/MacOS/draw.io"
    
    # Create test .drawio file
    echo "test content" > "$TEST_DIR/test.drawio"
    
    # Copy the script to test directory
    cp "export-drawio.sh" "$TEST_DIR/"
    cd "$TEST_DIR"

    # Set DRAWIO_PATH to mock executable
    export DRAWIO_PATH="$TEST_DIR/Applications/draw.io.app/Contents/MacOS/draw.io"
}

teardown() {
    cd -
    rm -rf "$TEST_DIR"
}

@test "shows usage when no arguments provided" {
    run ./export-drawio.sh
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ "Usage:" ]]
}

@test "processes single file with default scales" {
    run ./export-drawio.sh -i test.drawio
    [ "$status" -eq 0 ]
    # Check XML export
    [[ "${output}" =~ "Mock draw.io called with args: --export --format xml --uncompressed test.drawio" ]]
    # Check PNG export
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 0 -s 10 -t --output test-Page1.png test.drawio" ]]
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 1 -s 10 -t --output test-Page2.png test.drawio" ]]
    # Check SVG export
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 0 -s 4 -t --output test-Page1.svg test.drawio" ]]
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 1 -s 4 -t --output test-Page2.svg test.drawio" ]]
}

@test "processes single file with custom scales" {
    run ./export-drawio.sh -i test.drawio --png-scale 20 --svg-scale 8
    [ "$status" -eq 0 ]
    # Check XML export
    [[ "${output}" =~ "Mock draw.io called with args: --export --format xml --uncompressed test.drawio" ]]
    # Check PNG export
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 0 -s 20 -t --output test-Page1.png test.drawio" ]]
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 1 -s 20 -t --output test-Page2.png test.drawio" ]]
    # Check SVG export
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 0 -s 8 -t --output test-Page1.svg test.drawio" ]]
    [[ "${output}" =~ "Mock draw.io called with args: --export --page-index 1 -s 8 -t --output test-Page2.svg test.drawio" ]]
}

@test "processes all files in directory" {
    # Create additional test file
    echo "test content 2" > "$TEST_DIR/test2.drawio"
    
    run ./export-drawio.sh --all
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "test.drawio" ]]
    [[ "${output}" =~ "test2.drawio" ]]
}

@test "fails gracefully with non-existent input file" {
    run ./export-drawio.sh -i nonexistent.drawio
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "Input file nonexistent.drawio not found" ]]
}