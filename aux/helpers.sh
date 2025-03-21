#!/bin/bash

## Helper function to check if a directory exists, and mkdir if it doesn't
mkdir_if_needed () {
	local DIR_TO_CHECK="${1}"
	# echo "Checking.... ${DIR_TO_CHECK}"
	if [ ! -d "$DIR_TO_CHECK" ]; then
		echo "${DIR_TO_CHECK} does not exist, so creating now..."
		mkdir "${DIR_TO_CHECK}"
	fi
}

## Helper function to move the curser to the start of the line and delete following
## \033 for marking escape sequence
## 2K for Erase in Line
## \r carriage return
clearline () {
    printf "\033[2K\r"
}


str_multiply () {
    local ORIGSTR="$1"
    local COUNT="$2"
    printf -v myString '%*s' "$COUNT"
    printf '%s\n' "${myString// /$ORIGSTR}"
}


print_start_string () {
	printf "%s\n" \
  "##############################################################################" \
	"                                                                              " \
	" _        ______ _______   ______                                             " \
	"| |      | |       | |    / |                                                 " \
	"| |   _  | |----   | |    '------.                                            " \
	"|_|__|_| |_|____   |_|     ____|_/                                            " \
	"                                                                              " \
	" ______   ______ _______                                                      " \
	"| | ____ | |       | |                                                        " \
	"| |  | | | |----   | |                                                        " \
	"|_|__|_| |_|____   |_|                                                        " \
	"                                                                              " \
	" ______  _______  ______   ______  _______  ______  _____                     " \
	"/ |        | |   | |  | | | |  | \   | |   | |     | | \ \                    " \
	" ------.   | |   | |__| | | |__| |   | |   | |---- | |  | |                   " \
	" ____|_/   |_|   |_|  |_| |_|  \_\   |_|   |_|____ |_|_/_/                    " \
	"                                                                              " \
	"                                                                              " \
    "                    __                                                        " \
    "                 -=(o '.                                                      " \
    "                    '.-.\                                                     " \
    "                    /|  \\                                                    " \
    "                    '|  ||                                                    " \
    "                     _\_):,_                                                  " \
	"                                                                              " \
	"                                                                              " \
	"##############################################################################"
}


                                                            

print_end_string () {
	printf "%s\n" \
  "##############################################################################" \
  "                                                                              " \
  " ______   ______   _________   ______    ______   ______   _________   ______ " \
  "| |  \ \ | |  | | | | | | | \ | |       | | ____ | |  | | | | | | | \ | |     " \
  "| |  | | | |__| | | | | | | | | |----   | |  | | | |__| | | | | | | | | |---- " \
  "|_|  |_| |_|  |_| |_| |_| |_| |_|____   |_|__|_| |_|  |_| |_| |_| |_| |_|____ " \
  "                                                                      " \
  " ______   _    _   _________   ______   ______  ______   ______               " \
  "| |  \ \ | |  | | | | | | | \ | |  | \ | |     | |  | \ / |                   " \
  "| |  | | | |  | | | | | | | | | |--| < | |---- | |__| | '------.              " \
  "|_|  |_| \_|__|_| |_| |_| |_| |_|__|_/ |_|____ |_|  \_\  ____|_/              " \
  "                                                                      " \
  " ______  ______   _    _   ______   ______  _    _   ______  _____            " \
  "| |     | |  | \ | |  | | | |  \ \ | |     | |  | | | |     | | \ \           " \
  "| |     | |__| | | |  | | | |  | | | |     | |--| | | |---- | |  | |          " \
  "|_|____ |_|  \_\ \_|__|_| |_|  |_| |_|____ |_|  |_| |_|____ |_|_/_/           " \
  "                                                                              " \
  " (•_•)                                                                        " \
  " ( •_•)>⌐■-■                                                                  " \
  " (⌐■_■)                                                                       " \
  "                                                                              " \
  "##############################################################################"
}


top_message () {
	local TOPRINT="$1"
	echo ""
	str_multiply "#" ${#TOPRINT}
	# echo ${TOPRINT}
	printf '%s\n' "${TOPRINT}"
}

bottom_message () {
	local TOCHECKLENGTH="$1"
	str_multiply "#" ${#TOCHECKLENGTH}
	echo ""
}

clear_big_file_round_by_round() {
	var_dir_prep_round_by_round $1 $2 $3 $4
	# The only large output file is the full, model-derived round-by-round data
	# so rm after each iteration to greatly reduce storage
	rm "${ANALYSIS_DATA_FILE}"
}

var_dir_prep_round_by_round() {
	MEMSIZE=$1
	NOISELEVEL=$2
	POP_RULE=$3
	UPDATE_RULE=$4
	PICK_SECOND=${5:-""}

	CURR_OUTPUT_DIR="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}${PICK_SECOND}/"
	mkdir_if_needed "${CURR_OUTPUT_DIR}"
	ANALYSIS_DATA_FILE="${CURR_OUTPUT_DIR}/model_emp_results_round_by_round_all.tsv"
	ROUND_BY_ROUND_ABM_COMPARE_SIMPLE="${CURR_OUTPUT_DIR}/model_emp_results_round_by_round_simple_global_numbers.txt"
}

run_round_by_round_name_in_mem () {
	var_dir_prep_round_by_round $1 $2 $3 $4
	echo "NAME IN MEMORY ANALYSIS -- MemSize: ${MEMSIZE},  BRnoise: ${NOISELEVEL},  PopType: ${POP_RULE} ..."

	# Name Memory Things
	STOCASHTIC_MEMORY_OUTPUT_FILE_ALL="${CURR_OUTPUT_DIR}/top_name_ratio_output_explore_0.csv"
	STOCASHTIC_MEMORY_OUTPUT_FILE_POSTCONVERGE="${CURR_OUTPUT_DIR}/top_name_ratio_output_explore_22.csv"
	STOCASHTIC_MEMORY_FULL_DISTRO_OUTPUT_FILE="${CURR_OUTPUT_DIR}/name_memory_distro_explore.csv"
	NAME_IN_MEMORY_OUTPUT_FILE="${CURR_OUTPUT_DIR}/modeling_name_in_memory.tsv"
	python3 ./roundbyround/stochasticmemorycheck.py --datasourcefile "${ANALYSIS_DATA_FILE}" --outputfile "${STOCASHTIC_MEMORY_OUTPUT_FILE_ALL}" --outputfilefulldistro "${STOCASHTIC_MEMORY_FULL_DISTRO_OUTPUT_FILE}"  --startinground 0 && clearline
	python3 ./roundbyround/stochasticmemorycheck.py --datasourcefile "${ANALYSIS_DATA_FILE}" --outputfile "${STOCASHTIC_MEMORY_OUTPUT_FILE_POSTCONVERGE}" --outputfilefulldistro "${STOCASHTIC_MEMORY_FULL_DISTRO_OUTPUT_FILE}"  --startinground 22 && clearline
	Rscript ./roundbyround/name-in-memory.R "${CURR_OUTPUT_DIR}" "${ANALYSIS_DATA_FILE}" "${NAME_IN_MEMORY_OUTPUT_FILE}" "${STOCASHTIC_MEMORY_FULL_DISTRO_OUTPUT_FILE}" "${STOCASHTIC_MEMORY_OUTPUT_FILE_ALL}"

	clearline
}

run_round_by_round_single_setting () {
	var_dir_prep_round_by_round $1 $2 $3 $4
	echo "ROUND-BY-ROUND EMPIRICAL -- MemSize: ${MEMSIZE},  BRnoise: ${NOISELEVEL},  PopType: ${POP_RULE} ..."

	python3 ./roundbyround/unifiedempiricalnamegame.py --datasourcefile "${COMBINED_FILE}" --outputfile "${ANALYSIS_DATA_FILE}" --simplenumberfile "${ROUND_BY_ROUND_ABM_COMPARE_SIMPLE}" --memsize "${MEMSIZE}" --brnoise "${NOISELEVEL}" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}" # --verboseprint

	# Round by round analysis
	MODEL_ACCURACY_GLOBAL="${CURR_OUTPUT_DIR}/model_emp_results_total_accuracy.tsv"
	MODEL_ACCURACY_ROUND_BY_ROUND="${CURR_OUTPUT_DIR}/model_emp_results_roundbyround_accuracy.tsv"
	Rscript ./roundbyround/analyze-empirical-models.R "${CURR_OUTPUT_DIR}" "${ANALYSIS_DATA_FILE}" "${MODEL_ACCURACY_GLOBAL}" "${MODEL_ACCURACY_ROUND_BY_ROUND}"

	# clear_big_file_round_by_round $1 $2 $3 $4
	clearline

}

run_round_by_round_single_setting_pick_second () {
	var_dir_prep_round_by_round $1 $2 $3 $4 "-picksecond"
	echo "ROUND-BY-ROUND EMPIRICAL -- MemSize: ${MEMSIZE},  BRnoise: ${NOISELEVEL},  PopType: ${POP_RULE} PICK SECOND..."

	python3 ./roundbyround/unifiedempiricalnamegame.py --brpicksecond --datasourcefile "${COMBINED_FILE}" --outputfile "${ANALYSIS_DATA_FILE}" --simplenumberfile "${ROUND_BY_ROUND_ABM_COMPARE_SIMPLE}" --memsize "${MEMSIZE}" --brnoise "${NOISELEVEL}" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}" 

	# Round by round analysis
	MODEL_ACCURACY_GLOBAL="${CURR_OUTPUT_DIR}/model_emp_results_total_accuracy.tsv"
	MODEL_ACCURACY_ROUND_BY_ROUND="${CURR_OUTPUT_DIR}/model_emp_results_roundbyround_accuracy.tsv"
	Rscript ./roundbyround/analyze-empirical-models.R "${CURR_OUTPUT_DIR}" "${ANALYSIS_DATA_FILE}" "${MODEL_ACCURACY_GLOBAL}" "${MODEL_ACCURACY_ROUND_BY_ROUND}"

	# clear_big_file_round_by_round $1 $2 $3 $4
	clearline
}


run_round_by_round_single_setting_tp_gauss () {
	var_dir_prep_round_by_round $1 $2 $3 $4 "-TPgauss-${5}"
	echo "ROUND-BY-ROUND EMPIRICAL -- MemSize: ${MEMSIZE},  BRnoise: ${NOISELEVEL},  PopType: ${POP_RULE} TPgauss-${5}..."

	python3 ./roundbyround/unifiedempiricalnamegame.py --datasourcefile "${COMBINED_FILE}" --outputfile "${ANALYSIS_DATA_FILE}" --simplenumberfile "${ROUND_BY_ROUND_ABM_COMPARE_SIMPLE}" --memsize "${MEMSIZE}" --brnoise "${NOISELEVEL}" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}" --tpnoise "${5}" # --verboseprint

	# clear_big_file_round_by_round $1 $2 $3 $4
	clearline

}



