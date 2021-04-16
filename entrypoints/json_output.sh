#!/bin/bash

stdout_json(){
  local -a jsonfiles
  readarray -t jsonfiles < <(find "${JSON_TMP}" -type f -name "*.json")
  
  json_file="["
  json_delim=""
  for jfile in "${jsonfiles[@]}"; do
    file_contents=$(cat ${jfile})
    if [[ -n $file_contents ]]; then
      json_file+="${json_delim}${file_contents}"
      json_delim=","
    fi
  done
  json_file+="]"

  printf '%s' "${json_file}"

}
