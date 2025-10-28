#!/bin/bash

##  Author: Spencer Caplan
##  CUNY Graduate Center


############
## This is the main control script which can be used to execute the
## whole empirical analysis pipeline.
##
## Individual sections can be (en/dis)abled via these top flags
############
############
 

############
## Flags
RUN_MAIN_ROUND_BY_ROUND=true
RUN_NAME_SWITCHBACK_CALC=true
RUN_MIND_READING_GAME=true
RUN_COORD_PREPOST_TP=true
RUN_M_RANGE_EVAL=true
RUN_KEEPLAST_ROUND_BY_ROUND=true
RUN_TP_GAUSSNOISE=true
RUN_BRNOISE_ROUND_BY_ROUND=true
RUN_LUCENOISE_ROUND_BY_ROUND=true
RUN_TIPPING_POINT_BAYES_SIMULATION=true
RUN_PURESIM_CONVERGENCE=true
RUN_CRITICAL_MASS_SIMULATION=true 
RUN_PERCENT_BR_MIX=true

EXTRACT_PAPER_FIGS=true 
############
############



############
## Get directory variables ready

## This can be adjusted based on host system, but it should work if
## the repo is freshly cloned (relative paths configured already)
PIPELINE_BASE_PATH=`pwd`
source "${PIPELINE_BASE_PATH}/aux/helpers.sh"
source "${PIPELINE_BASE_PATH}/aux/extractpaperfigs.sh"
DATA_BASE_PATH="${PIPELINE_BASE_PATH}/data"
STAT_PLOT_DIR="${PIPELINE_BASE_PATH}/output"
MR_BASE_PATH="${DATA_BASE_PATH}/MR"
PAPER_DIR="${PIPELINE_BASE_PATH}/paperfigs"
mkdir_if_needed "${STAT_PLOT_DIR}/"
mkdir_if_needed "${PAPER_DIR}/"
PREPOST_DIR="${STAT_PLOT_DIR}/prepostthreshold"
SIMULATION_DIR="${STAT_PLOT_DIR}/simulation"
BAYES_DIR="${STAT_PLOT_DIR}/bayestippingpoint/"
BAYES_PLOT_OUT_DIR="${BAYES_DIR}plots/"
MODEL_EMPIRICAL_DIR="${STAT_PLOT_DIR}/model_empirical_roundbyround/"
mkdir_if_needed "${PREPOST_DIR}"
mkdir_if_needed "${BAYES_DIR}"
mkdir_if_needed "${SIMULATION_DIR}"
mkdir_if_needed "${BAYES_PLOT_OUT_DIR}"
mkdir_if_needed "${MODEL_EMPIRICAL_DIR}"
COMBINED_FILE="${DATA_BASE_PATH}/NameGame-2015-2018-all.tsv"
print_start_string
############
############


############
## Empirical round-by-round analysis
## Main Figure 1
if [ "$RUN_MAIN_ROUND_BY_ROUND" = true ] ; then 
	MAIN_FIG1_STRING="Running main Figure 1 analysis (round-by-round, primary configuration)..."
	top_message "${MAIN_FIG1_STRING}"

	MEMSIZE="10" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	MEMSIZE="11" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	MEMSIZE="12" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
	run_round_by_round_name_in_mem "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	MEMSIZE="13" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	MEMSIZE="14" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	# Extract and plot 10, 11, 13, 14
	TWO_THIRDS_COMPARE="${MODEL_EMPIRICAL_DIR}TWO_THIRDS_COMPARE.tsv"
	echo -e "MEMSIZE\tTP-CORRECT\tTWOTHIRDS-CORRECT\tTOTAL-ROUNDS" > "$TWO_THIRDS_COMPARE"
	for MEMSIZE in "10" "11" "13" "14"; do
		var_dir_prep_round_by_round "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
		grep "^Head-to-head (TP, 2/3rds)" "$ROUND_BY_ROUND_ABM_COMPARE_SIMPLE" | \
	    awk -v mem="$MEMSIZE" '{
	        printf "%s", mem        # Print MEMSIZE first
	        first_num = 1
	        for(i=2;i<=NF;i++) {
	            if($i ~ /^[0-9]+$/) {
	                printf "\t%s", $i
	            }
	        }
	        print ""                # newline
	    }' >> "$TWO_THIRDS_COMPARE"
	done

	## Two-Thirds compare Figure for SI
	Rscript ./roundbyround/plottwothirdscompare.R "${MODEL_EMPIRICAL_DIR}" "${TWO_THIRDS_COMPARE}"
	

	bottom_message "${MAIN_FIG1_STRING}"
fi
############
############



############
## Name Switchback
if [ "$RUN_NAME_SWITCHBACK_CALC" = true ] ; then 
	SWITCHBACK_STRING="Calculating name switch-back probability..."
	top_message "${SWITCHBACK_STRING}"
	NAME_SWITCH_DIR="${STAT_PLOT_DIR}/nameswitchback/"
	python3 ./switchback/nameswitchbackprob.py --datasourcefile "${COMBINED_FILE}" --outputdir "${NAME_SWITCH_DIR}" > "${NAME_SWITCH_DIR}/nameswitchback_global_numbers.txt"
	bottom_message "${SWITCHBACK_STRING}"
fi
############
############



############
## New Mind Reading game analysis
if [ "$RUN_MIND_READING_GAME" = true ] ; then 
	MINDREADING_STRING="Analysis and simulations for Mind Reading Game..."
	top_message "${MINDREADING_STRING}"
	declare -a MR_RUN_ARRAY=("16_5_8" "18_6_9" "20_6_10" "24_7_12")
	declare -a MEMSIZE_ARRAY=("12")
	declare -a VARIANCE_ARRAY=("1" "2" "3" "4")
	for MEMSIZE in "${MEMSIZE_ARRAY[@]}" ; do
		for VARIANCE in "${VARIANCE_ARRAY[@]}" ; do
			run_mind_reading_simulation "${STAT_PLOT_DIR}/mind_reading" "${MEMSIZE}" "${VARIANCE}" "PENALIZE"
			run_mind_reading_simulation "${STAT_PLOT_DIR}/mind_reading" "${MEMSIZE}" "${VARIANCE}" "BUFFER"
		done
	done
	bottom_message "${MINDREADING_STRING}"
fi
############
############




############
## Coordination Success Pre-Post TP
if [ "$RUN_COORD_PREPOST_TP" = true ] ; then 
	COORD_STRING="Calculating coordination success before and after reaching TP..."
	top_message "${COORD_STRING}"
	MEMSIZE="12" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	COORDPROB_OUT="${PREPOST_DIR}/coordprob_output_${MEMSIZE}.tsv"
	COORDPROB_FIRST_HIT_TP="${PREPOST_DIR}/first_hit_threshold_${MEMSIZE}.tsv"

	python3 ./prepostthreshold/coordprob.py --datasourcefile "${COMBINED_FILE}" --outputfile "${COORDPROB_OUT}" --outputfirsthitTP "${COORDPROB_FIRST_HIT_TP}" --memsize "${MEMSIZE}" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}"
	Rscript ./prepostthreshold/plotcoord.R "${PREPOST_DIR}" "${COORDPROB_OUT}" "${COORDPROB_FIRST_HIT_TP}" && clearline

	COORDPROB_OUT="${PREPOST_DIR}/coordprob_output_RANDO.tsv"
	COORDPROB_FIRST_HIT_TP="${PREPOST_DIR}/first_hit_threshold_RANDO.tsv"
	python3 ./prepostthreshold/coordprob.py --datasourcefile "${COMBINED_FILE}" --outputfile "${COORDPROB_OUT}" --outputfirsthitTP "${COORDPROB_FIRST_HIT_TP}" --memsize "RANDOM" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}"
	Rscript ./prepostthreshold/plotcoord.R "${PREPOST_DIR}" "${COORDPROB_OUT}" "${COORDPROB_FIRST_HIT_TP}" && clearline

	declare -a MEMSIZE_ARRAY=("10" "12" "14")
	for MEMSIZE in "${MEMSIZE_ARRAY[@]}" ; do
		INDUCE_TP_OUT="${PREPOST_DIR}/check_other_thresholds_output_${MEMSIZE}.tsv"
		python3 ./prepostthreshold/checkotherthresholds.py --datasourcefile "${COMBINED_FILE}" --outputfile "${INDUCE_TP_OUT}" --memsize "${MEMSIZE}" --poprule "${POP_RULE}" --updaterule "${UPDATE_RULE}"  && clearline
	done

	# Add plotting for induce TP
	Rscript ./prepostthreshold/plotinducethreshold.R "${PREPOST_DIR}" "${PREPOST_DIR}/check_other_thresholds_output_10.tsv"  && clearline
	Rscript ./prepostthreshold/plotinducethreshold.R "${PREPOST_DIR}" "${PREPOST_DIR}/check_other_thresholds_output_12.tsv"  && clearline
	Rscript ./prepostthreshold/plotinducethreshold.R "${PREPOST_DIR}" "${PREPOST_DIR}/check_other_thresholds_output_14.tsv"  && clearline

	bottom_message "${COORD_STRING}" 
fi
############
############


############
## ABM model scores over different M
if [ "$RUN_M_RANGE_EVAL" = true ] ; then

	if [ "$RUN_MAIN_ROUND_BY_ROUND" = false ] ; then
		# echo "Can't run M search without running base M=12 condition"
		MEMSIZE="12" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
		run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
		# name safe to assume $MODEL_EMPIRICAL_DIR exists
	fi
	NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE" ## Set non-M parameters
	MODEL_SCORES_ACROSS_M="${MODEL_EMPIRICAL_DIR}model_scores_across_M.tsv"
	TOTAL_SCORE_HEADER="${MODEL_EMPIRICAL_DIR}M-12_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/model_emp_results_total_accuracy.tsv"
	head -n 1 $TOTAL_SCORE_HEADER > $MODEL_SCORES_ACROSS_M
	
	declare -a MEMSIZE_ARRAY=("8" "10" "12" "14" "16" "18" "20" "22" "24" "26")
	for MEMSIZE in "${MEMSIZE_ARRAY[@]}" ; do
		run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
		TOTAL_SCORES="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/model_emp_results_total_accuracy.tsv"
		tail -n 3 $TOTAL_SCORES >> $MODEL_SCORES_ACROSS_M
	done

	# global accuracy by M
	Rscript ./roundbyround/plottotalaccuracybymemsize.R "${MODEL_EMPIRICAL_DIR}" "${MODEL_SCORES_ACROSS_M}"

	# cowplot side-by-side for r-by-r
	M8PATH="${MODEL_EMPIRICAL_DIR}M-8_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/fig1_rbyr_accuracy_combined_new_zoomin.png"
	M10PATH="${MODEL_EMPIRICAL_DIR}M-10_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/fig1_rbyr_accuracy_combined_new_zoomin.png"
	M14PATH="${MODEL_EMPIRICAL_DIR}M-14_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/fig1_rbyr_accuracy_combined_new_zoomin.png"
	M16PATH="${MODEL_EMPIRICAL_DIR}M-16_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}/fig1_rbyr_accuracy_combined_new_zoomin.png"
	Rscript ./roundbyround/plotroundbyroundgridformemsize.R "${MODEL_EMPIRICAL_DIR}" "${M8PATH}" "${M10PATH}" "${M14PATH}" "${M16PATH}"
fi
############
############


############
## Keep Last / Bag Implementation
if [ "$RUN_KEEPLAST_ROUND_BY_ROUND" = true ] ; then 
	
	# BUFFER version for SI
	MEMSIZE="12" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="BUFFER"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"

	# BAG memory rather than FIFO version for SI
	MEMSIZE="12" NOISELEVEL="0" POP_RULE="BAG" UPDATE_RULE="PENALIZE"
	run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
fi
############
############



############
## Vary TP according to some normal distribution (centered at true TP)
if [ "$RUN_TP_GAUSSNOISE" = true ] ; then 
	TP_GAUSSNOISE_STRING="Running TP normal distribution analysis..."
	top_message "${TP_GAUSSNOISE_STRING}"

	if [ "$RUN_MAIN_ROUND_BY_ROUND" = false ] ; then
		# echo "Can't run M search without running base M=12 condition"
		MEMSIZE="12" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
		run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
	fi 

	TP_GAUSS_RESULT_FILE="${MODEL_EMPIRICAL_DIR}/TP_GAUSS_RESULT.tsv"
	
	MEMSIZE="12" NOISELEVEL="0" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	ACC_F="model_emp_results_total_accuracy.tsv"
	ACC_BASE="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-${NOISELEVEL}_pop-${POP_RULE}_update-${UPDATE_RULE}"
	echo -e "STD_DEV\tACCURACY" > "${TP_GAUSS_RESULT_FILE}"

	run_round_by_round_single_setting_tp_gauss "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}" "0.1"
	run_round_by_round_single_setting_tp_gauss "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}" "0.5"
	run_round_by_round_single_setting_tp_gauss "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}" "1"
	run_round_by_round_single_setting_tp_gauss "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}" "2"
	run_round_by_round_single_setting_tp_gauss "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}" "3"

	# awk/cat all the accuracy results into a single file
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}/${ACC_F}" | awk '{print $0 "\t0"}' >> "${TP_GAUSS_RESULT_FILE}"
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}-TPgauss-0.1/${ACC_F}" | awk '{print $0 "\t0.1"}' >> "${TP_GAUSS_RESULT_FILE}"
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}-TPgauss-0.5/${ACC_F}" | awk '{print $0 "\t0.5"}' >> "${TP_GAUSS_RESULT_FILE}"
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}-TPgauss-1/${ACC_F}" | awk '{print $0 "\t1"}' >> "${TP_GAUSS_RESULT_FILE}"
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}-TPgauss-2/${ACC_F}" | awk '{print $0 "\t2"}' >> "${TP_GAUSS_RESULT_FILE}"
	awk -F'\t' 'NR==4 {print $10}' "${ACC_BASE}-TPgauss-3/${ACC_F}" | awk '{print $0 "\t3"}' >> "${TP_GAUSS_RESULT_FILE}"

	bottom_message "${TP_GAUSSNOISE_STRING}"
fi
############
############


############
## BR+Noise analysis
if [ "$RUN_BRNOISE_ROUND_BY_ROUND" = true ] ; then 
	BRNOISE_STRING="Running BR+Noise analysis..."
	top_message "${BRNOISE_STRING}"
	MEMSIZE="12" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	declare -a BRNOISE_ARRAY=("0" "1" "2" "3" "4")
	for NOISELEVEL in "${BRNOISE_ARRAY[@]}" ; do
		run_round_by_round_single_setting "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
		run_round_by_round_single_setting_pick_second "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
	done
	## Simple plot to compare BR+Noise
	N0PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-0_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N1PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-1_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N2PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-2_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N3PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-3_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N4PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_noise-4_pop-${POP_RULE}_update-${UPDATE_RULE}"

	N0PATH_FULL="${N0PATH}/model_emp_results_total_accuracy.tsv"
	N1PATH_FULL="${N1PATH}/model_emp_results_total_accuracy.tsv"
	N2PATH_FULL="${N2PATH}/model_emp_results_total_accuracy.tsv"
	N3PATH_FULL="${N3PATH}/model_emp_results_total_accuracy.tsv"
	N4PATH_FULL="${N4PATH}/model_emp_results_total_accuracy.tsv"
	Rscript ./roundbyround/plotbrwithnoise.R "${MODEL_EMPIRICAL_DIR}" "${N0PATH_FULL}" "${N1PATH_FULL}" "${N2PATH_FULL}" "${N3PATH_FULL}" "${N4PATH_FULL}"  && clearline

	Rscript ./roundbyround/plotbrwithnoise-randomsecond.R "${MODEL_EMPIRICAL_DIR}" "${N0PATH}" "${N1PATH}" "${N2PATH}" "${N3PATH}" "${N4PATH}" "model_emp_results_round_by_round_all.tsv"

	bottom_message "${BRNOISE_STRING}"
fi
############
############



############
## Luce+Noise analysis
if [ "$RUN_LUCENOISE_ROUND_BY_ROUND" = true ] ; then 
	LUCENOISE_STRING="Running Luce+Noise analysis..."
	top_message "${LUCENOISE_STRING}"
	
	MEMSIZE="12" POP_RULE="FIFO" UPDATE_RULE="PENALIZE"
	declare -a LUCENOISE_ARRAY=("0" "1" "2" "3" "4")
	for NOISELEVEL in "${LUCENOISE_ARRAY[@]}" ; do
		run_round_by_round_single_setting_luce_noise "${MEMSIZE}" "${NOISELEVEL}" "${POP_RULE}" "${UPDATE_RULE}"
	done
	# Simple plot to compare BR+Noise
	N0PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_LuceNoise-0_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N1PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_LuceNoise-1_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N2PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_LuceNoise-2_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N3PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_LuceNoise-3_pop-${POP_RULE}_update-${UPDATE_RULE}"
	N4PATH="${MODEL_EMPIRICAL_DIR}M-${MEMSIZE}_LuceNoise-4_pop-${POP_RULE}_update-${UPDATE_RULE}"

	N0PATH_FULL="${N0PATH}/model_emp_results_round_by_round_all.tsv"
	N1PATH_FULL="${N1PATH}/model_emp_results_round_by_round_all.tsv"
	N2PATH_FULL="${N2PATH}/model_emp_results_round_by_round_all.tsv"
	N3PATH_FULL="${N3PATH}/model_emp_results_round_by_round_all.tsv"
	N4PATH_FULL="${N4PATH}/model_emp_results_round_by_round_all.tsv"
	Rscript ./roundbyround/plotlucewithnoise.R "${MODEL_EMPIRICAL_DIR}" "${N0PATH_FULL}" "${N1PATH_FULL}" "${N2PATH_FULL}" "${N3PATH_FULL}" "${N4PATH_FULL}"  && clearline

	bottom_message "${LUCENOISE_STRING}"
fi
############
############



############
## Tipping point Bayesian simulation
if [ "$RUN_TIPPING_POINT_BAYES_SIMULATION" = true ] ; then 
	BAYES_STRING="Running Bayesian tipping point simulation..."
	top_message "${BAYES_STRING}"
	
	BAYES_OUTPUT_FILEROUNDBYROUND="${BAYES_DIR}bayes_tipping_point_simulation_roundbyround.csv"
	BAYES_OUTPUT_FILESUMMARY="${BAYES_DIR}bayes_tipping_point_simulation_summary.csv"
	
	python3 bayes/bayestippingpointsimulation.py --outputfileroundbyround "${BAYES_OUTPUT_FILEROUNDBYROUND}" --outputfilesummary "${BAYES_OUTPUT_FILESUMMARY}"
	Rscript bayes/bayesparamsifting.R "${BAYES_DIR}" "${BAYES_OUTPUT_FILESUMMARY}"
	Rscript bayes/plotbayes.R "${BAYES_DIR}" "${BAYES_OUTPUT_FILEROUNDBYROUND}" "${BAYES_PLOT_OUT_DIR}"
	
	bottom_message "${BAYES_STRING}"
fi
############
############



############
## Pure tipping point (critical mass) Simulations
if [ "$RUN_PURESIM_CONVERGENCE" = true ] ; then 
	CONVERGENCE_STRING="Simulating initial convergence speed..."
	top_message "${CONVERGENCE_STRING}"

	echo -e "AGENT_TYPE\tN\tM\tW\tCONVERGED_SIMS\tTOTAL_SIMS\tMEAN_ROUND\tSTD_DEV" > "${SIMULATION_DIR}/converge_puresim_outcomes_combined.tsv"
	
	declare -a WORD_SET=("10" "100")
	declare -a NETWORK_SIZES=("24" "48" "96")
	declare -a AGENTS=("TP" "BR" "CB" "Luce")
	for NUM_WORDS in "${WORD_SET[@]}" ; do
		for N in "${NETWORK_SIZES[@]}" ; do
			for ABM in "${AGENTS[@]}" ; do
				python3 ./critmass/puresimconverge.py --agents "${ABM}" -N "${N}" -W "${NUM_WORDS}" -M "12" --outputconvergefile "${SIMULATION_DIR}/converge_puresim_outcomes_combined.tsv"
			done
		done
	done

	Rscript ./critmass/puresim_table.R "${SIMULATION_DIR}" "converge_puresim_outcomes_combined.tsv" "converge_puresim_table.txt"

	clearline

	bottom_message "${CONVERGENCE_STRING}"
fi
############
############


############
## Pure tipping point (critical mass) Simulations
if [ "$RUN_CRITICAL_MASS_SIMULATION" = true ] ; then 
	CONVERGENCE_STRING="Simulating critical mass convergence conditions (2018 data)..."
	top_message "${CONVERGENCE_STRING}"

	CRITMASS_OUTCOMES_FILE="${SIMULATION_DIR}/critmass_final_flip_outcomes.tsv"

	echo -e "AGENT_TYPE\tN\tL\tM\tCM\tSIMULATION_NUMBER\tNEW_PROP\tFIRST_FLIP" > "${CRITMASS_OUTCOMES_FILE}"
	declare -a NETWORK_SIZES=("24" "48" "96")
	for CM in $(seq 0.0 0.02 0.5); do
		for N in "${NETWORK_SIZES[@]}" ; do
			python3 ./critmass/criticalmass.py --agents "TP" -N "${N}" -CM "${CM}" -M "12" --outputdir "${SIMULATION_DIR}" --outputflipfile "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_TP_outcomes.tsv" &
			python3 ./critmass/criticalmass.py --agents "BR" -N "${N}" -CM "${CM}" -M "12" --outputdir "${SIMULATION_DIR}" --outputflipfile "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_BR_outcomes.tsv" &
			python3 ./critmass/criticalmass.py --agents "CB" -N "${N}" -CM "${CM}" -M "12" --outputdir "${SIMULATION_DIR}" --outputflipfile "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_CB_outcomes.tsv" &
			python3 ./critmass/criticalmass.py --agents "Luce" -N "${N}" -CM "${CM}" -M "12" --outputdir "${SIMULATION_DIR}" --outputflipfile "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_Luce_outcomes.tsv" &
		done

		wait && clearline

		for N in "${NETWORK_SIZES[@]}" ; do
			cat "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_TP_outcomes.tsv" >> "${CRITMASS_OUTCOMES_FILE}"
			cat "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_BR_outcomes.tsv" >> "${CRITMASS_OUTCOMES_FILE}"
			cat "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_CB_outcomes.tsv" >> "${CRITMASS_OUTCOMES_FILE}"
			cat "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_Luce_outcomes.tsv" >> "${CRITMASS_OUTCOMES_FILE}"
			rm "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_TP_outcomes.tsv"
			rm "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_BR_outcomes.tsv"
			rm "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_CB_outcomes.tsv"
			rm "${SIMULATION_DIR}/critmass_final_flip_CM${CM}_N${N}_temp_Luce_outcomes.tsv"
		done
	done

	Rscript ./critmass/plotcritmass.R "${SIMULATION_DIR}" "${CRITMASS_OUTCOMES_FILE}"  && clearline
	
	python3 ./critmass/critmasscompareempirical.py --empiricaldata "${DATA_BASE_PATH}/Empirical-CBBB2018-Flipping.tsv" -M "12" --updaterule "PENALIZE" --outputdir "${SIMULATION_DIR}"
	Rscript ./critmass/plotcritmassempiricalcompare.R "${SIMULATION_DIR}" "empirical_flipping_compare_puresum.tsv" "Pure Simulation"  && clearline

	# python3 ./critmass/critmasscompareempirical.py --empiricaldata "${DATA_BASE_PATH}/Empirical-CBBB2018-Flipping.tsv" -M "12"  --empiricalmemory "${DATA_BASE_PATH}/agent_mem_at_confed_enter.tsv" --updaterule "PENALIZE" --outputdir "${SIMULATION_DIR}/empiricalmemory/"
	# Rscript ./critmass/plotcritmassempiricalcompare.R "${SIMULATION_DIR}/empiricalmemory/" "empirical_flipping_compare_puresum.tsv" "Empirically Calibrated to Participants' Memory"  && clearline
	
	python3 ./critmass/critmasscompareempirical.py --empiricaldata "${DATA_BASE_PATH}/Empirical-CBBB2018-Flipping.tsv" -M "12" --empiricalhaltpoint "TRUE" --updaterule "PENALIZE" --outputdir "${SIMULATION_DIR}/haltempirical/"
	Rscript ./critmass/plotcritmassempiricalcompare.R "${SIMULATION_DIR}/haltempirical/" "empirical_flipping_compare_puresum.tsv" "Pure Simulation (Exact Convergence Window)"  && clearline

	# BUFFER version for SI
	python3 ./critmass/critmasscompareempirical.py --empiricaldata "${DATA_BASE_PATH}/Empirical-CBBB2018-Flipping.tsv" -M "12" --updaterule "BUFFER" --outputdir "${SIMULATION_DIR}/keeplast/"
	Rscript ./critmass/plotcritmassempiricalcompare.R "${SIMULATION_DIR}/keeplast/" "empirical_flipping_compare_puresum.tsv" "Pure Simulation (Memory: Keep Last)"  && clearline

	bottom_message "${CONVERGENCE_STRING}"
fi
############
############


############
## % BR simulation
if [ "$RUN_PERCENT_BR_MIX" = true ] ; then 
	PERCENT_BR_STRING="Simulating convergence under %BR mixed with 100-% of Luce agents..."
	top_message "${PERCENT_BR_STRING}"
	
	echo -e "AGENT_TYPE\tN\tL\tM\tCM\tSIMULATION_NUMBER\tNEW_PROP\tFIRST_FLIP" > "${SIMULATION_DIR}/critmass_percentLuce_final_flip_outcomes.tsv"
	declare -a NETWORK_SIZES=("24" "48" "96")
	# declare -a NETWORK_SIZES=("24")
	for CM in $(seq 0.0 0.02 0.5); do
		for N in "${NETWORK_SIZES[@]}" ; do
			for LUCE in $(seq 0 10 90); do
				python3 ./critmass/criticalmass.py --agents "BR" -N "${N}" -L "${LUCE}" -CM "${CM}" -M "12" --outputdir "${SIMULATION_DIR}" --outputflipfile "${SIMULATION_DIR}/critmass_percentLuce_final_flip_CM${CM}_N${N}_L${LUCE}_temp_BR_outcomes.tsv" &
			done
		done

		wait

		for N in "${NETWORK_SIZES[@]}" ; do
			for LUCE in $(seq 0 10 90); do
				cat "${SIMULATION_DIR}/critmass_percentLuce_final_flip_CM${CM}_N${N}_L${LUCE}_temp_BR_outcomes.tsv" >> "${SIMULATION_DIR}/critmass_percentLuce_final_flip_outcomes.tsv"
				rm "${SIMULATION_DIR}/critmass_percentLuce_final_flip_CM${CM}_N${N}_L${LUCE}_temp_BR_outcomes.tsv"
			done
		done
	done

	Rscript ./critmass/plotcritmass_mixluce.R "${SIMULATION_DIR}" "${SIMULATION_DIR}/critmass_percentLuce_final_flip_outcomes.tsv"

	bottom_message "${PERCENT_BR_STRING}"
fi
############
############




############
## cp over generated figures for paper into unique dir
if [ "$EXTRACT_PAPER_FIGS" = true ] ; then
	PAPER_STRING="extracting final paper figures to own directory..."
	top_message "${PAPER_STRING}"
	extract_paper_figs "${STAT_PLOT_DIR}" "${PAPER_DIR}"
	extract_paper_numbers "${STAT_PLOT_DIR}" "${PAPER_DIR}"
	bottom_message "${PAPER_STRING}"
fi
############
############


############
############
print_end_string
############
############




