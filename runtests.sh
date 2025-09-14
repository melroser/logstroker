#!/bin/bash

# Logstroker Test Runner
echo "=== Running All Logstroker Tests ==="

passed=0
failed=0

for test_file in test/*.vim; do
    test_name=$(basename "$test_file" .vim)
    echo -n "Running $test_name... "
    
    # Run with timeout to prevent hanging
    output=$(timeout 10s vim -u NONE --noplugin -c "source $test_file | :qall" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        echo "❌ TIMEOUT"
        ((failed++))
    elif echo "$output" | grep -q -E "(✗|FAIL|ERROR|Exception)"; then
        echo "❌ FAILED"
        echo "$output" | grep -E "(✗|FAIL|ERROR|Exception)" | head -2
        ((failed++))
    else
        echo "✅ PASSED"
        ((passed++))
    fi
done

echo ""
echo "=== Test Summary ==="
echo "Passed: $passed"
echo "Failed: $failed"
echo "Total: $((passed + failed))"