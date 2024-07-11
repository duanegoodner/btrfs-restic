#!/bin/bash

# serialization and deserialization utility functions

# serializes an associative array into a string
serialize_map() {
    local -n map=$1
    local serialized_map=""

    for key in "${!map[@]}"; do
        serialized_map+="$key:${map[$key]} "
    done

    # Remove trailing comma
    serialized_map="${serialized_map%' '}"

    echo "$serialized_map"
}

# Deserializes string of space delimited key:val pairs into an associative array
deserialize_map() {
    local serialized_map=$1
    declare -n deserialized_array="$2"

    # Split the string by spaces
    IFS=' ' read -r -a entries <<< "$serialized_map"

    # Iterate over each entry
    for entry in "${entries[@]}"; do
        # Split the entry by ":"
        IFS=':' read -r key value <<< "$entry"
        # Add to associative array
        # shellcheck disable=SC2034
        deserialized_array["$key"]="$value"
    done
}

# gets each value from an array of key:value pairs and serializes as space delimited string
get_vals() {
    local array=("$@")
    local values=()
    
    for item in "${array[@]}"; do
        IFS=":" read -r _ value <<< "$item"
        values+=("$value")
    done
    
    echo "${values[@]}"
}

# deserializes string of space delimited elments into an array
deserialize_array() {
    local str="$1"
    declare -n arr=$2
    IFS=' ' read -r -a arr <<< "$str"
}

# serializes an array into as string of space delimited elements
serialize_array() {
    local arr_name="$1"
    local arr=("${!arr_name}")
    local str="${arr[*]}"
    echo "$str"
}

