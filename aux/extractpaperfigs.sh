#!/bin/bash

extract_paper_figs() {
	STAT_PLOT_DIR=$1
	PAPER_DIR=$2

	# Fig 1 is the illustrative schematic of the name game...
	### Numering of output files [2-5] doesn't reflect that for back-compatibility


	# Fig 2 pre-post threshold
	Rscript ./aux/gridfig1.R "${PAPER_DIR}" "${STAT_PLOT_DIR}/prepostthreshold/Coord-Success-Pre-Post-TP-12.png" "${STAT_PLOT_DIR}/prepostthreshold/Induce-threshold-magnitude-12.png" "SC_fig1_prepost.png"
	Rscript ./aux/gridfig1.R "${PAPER_DIR}" "${STAT_PLOT_DIR}/prepostthreshold/Induce-threshold-magnitude-10.png" "${STAT_PLOT_DIR}/prepostthreshold/Induce-threshold-magnitude-14.png" "SC_SI_prepost_induce_TP_different_M.png"

	# Fig 3 R-by-R
	ROUND_BY_ROUND_DIR="${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE"
	Rscript ./aux/gridfig2.R "${PAPER_DIR}" "${ROUND_BY_ROUND_DIR}/Name-in-mem-vs-output-superearly.png" "${ROUND_BY_ROUND_DIR}/fig1_rbyr_accuracy_combined_new_zoomin.png"  "${STAT_PLOT_DIR}/model_empirical_roundbyround/figS1_total_accuracy_by_M.png" "SC_fig2_twostage_rbyr.png"

	# Fig 4 tipping point
	Rscript ./aux/gridfig3.R "${PAPER_DIR}" "${STAT_PLOT_DIR}/simulation/InitialConverge.png" "${STAT_PLOT_DIR}/simulation/CritMass_ProbFlip.png" "SC_fig3_flipping.png"

	# Fig 5 mind reading
	cp "${STAT_PLOT_DIR}/mind_reading/M-12_var-2_update-PENALIZE/SC_MR_Results.png" "${PAPER_DIR}/SC_fig4_mindreading.png"
	cp "${STAT_PLOT_DIR}/mind_reading/M-12_var-2_update-BUFFER/SC_MR_Results.png" "${PAPER_DIR}/SC_SI_keeplast_mindreading.png"



	######  Below is all SI stuff ######
	# SI Two-Thirds comparison
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/SI_compare_TP_two-thirds.png" "${PAPER_DIR}/SC_SI_compare_TP_two-thirds.png"

	# SI critmass puresim
	cp "${STAT_PLOT_DIR}/simulation/CritMass_EmpiricalCompare.png" "${PAPER_DIR}/SC_SI_puresim_conv.png"

	# SI critmass keep last
	cp "${STAT_PLOT_DIR}/simulation/keeplast/CritMass_EmpiricalCompare.png" "${PAPER_DIR}/SC_SI_keeplast_emp_conv.png"


	# SI critmass halt empirical stopping round
	cp "${STAT_PLOT_DIR}/simulation/haltempirical/CritMass_EmpiricalCompare.png" "${PAPER_DIR}/SC_SI_exact_conv_convergence_stop.png"


	# SI R-by-R
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/SI_fig2_rbyr_across_M.png" "${PAPER_DIR}/SC_SI_fig2_rbyr_across_M.png"


	# Coordination Success (pre-post TP)
	cp "${STAT_PLOT_DIR}/prepostthreshold/Coord-Success-Pre-Post-TP-RANDOM.png" "${PAPER_DIR}/SC_SI_coord_success_prepost_TP_M_robust.png"
	cp "${STAT_PLOT_DIR}/prepostthreshold/BR-Accuracy-Pre-Post-TP-12.png" "${PAPER_DIR}/SC_SI_BR_accuracy_prepost_TP_12.png"


	# Name in memory vs. output production correlation
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/Name-in-mem-vs-output.png" "${PAPER_DIR}/SC_SI_memory_slots_vs_output_prop.png"


	# SI M-robust
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/figS1_total_accuracy_by_M.png" "${PAPER_DIR}/SC_SI_fig1_M_robust.png"


	# SI threshold speed variation
	cp "${STAT_PLOT_DIR}/prepostthreshold/Participant-Variation-Threshold-Speed-12.png" "${PAPER_DIR}/SC_SI_threshold_speed.png"


	# SI Buffer
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-BUFFER/fig1_rbyr_accuracy_combined_new_zoomin.png" "${PAPER_DIR}/SC_SI_keeplast_rbyr.png"


	# SI BR+Noise
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/SI_rbyr_accuracy_BRwithNoise.png" "${PAPER_DIR}/SC_SI_rbyr_accuracy_BRwithNoise.png"
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/SI_rbyr_accuracy_BRwithNoisePickSecond.png" "${PAPER_DIR}/SC_SI_rbyr_accuracy_BRwithNoisePickSecond.png"


	# SI BR+Noise Critical Mass
	cp "${STAT_PLOT_DIR}/simulation/CritMass_ProbFlip_MixLuce.png" "${PAPER_DIR}/SC_SI_CritMass_ProbFlip_MixLuce.png"

	# SI Luce+Noise
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/SI_rbyr_accuracy_LucewithNoisePickSecondChoice.png" "${PAPER_DIR}/SC_SI_rbyr_accuracy_LucewithNoisePickSecondChoice.png"


	# SI Bayes Analysis
	cp "${STAT_PLOT_DIR}/bayestippingpoint/plots/Bayes-tipping-point-PRIOR-0.8-SCALAR-0.22.png" "${PAPER_DIR}/SC_SI_bayes_figure.png"

}



extract_paper_numbers() {
	STAT_PLOT_DIR=$1
	PAPER_DIR=$2
	
	# Fig 1 accuracy
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/model_emp_results_total_accuracy.tsv" "${PAPER_DIR}/numbers/main_rbyr_avg_accuracy.tsv"
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/proportion-tests.txt" "${PAPER_DIR}/numbers/main_rbyr_prop-tests.txt"

	# Switch-back rate
	cp "${STAT_PLOT_DIR}/nameswitchback/nameswitchback_global_numbers.txt" "${PAPER_DIR}/numbers/nameswitchback_rates.txt"

	# pre-threshold plurality output
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/below_TP_plurality_output_vs_mem.txt" "${PAPER_DIR}/numbers/pre-threshold_plurality_rate.txt"

	# pre-TP early rounds coordination success and BR accuracy
	cp "${STAT_PLOT_DIR}/prepostthreshold/pre-TP-coord-prob-plus-BR-accuracy.txt" "${PAPER_DIR}/numbers/pre-TP-coord-prob-plus-BR-accuracy.txt"

	# keep-last accuracy
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-BUFFER/model_emp_results_total_accuracy.tsv" "${PAPER_DIR}/numbers/keeplast_rbyr_avg_accuracy.tsv"

	# convergence speed simulation
	cp "${SIMULATION_DIR}/converge_puresim_outcomes_combined.tsv" "${PAPER_DIR}/numbers/converge_puresim_outcomes.tsv"
	cp "${SIMULATION_DIR}/converge_puresim_table.txt" "${PAPER_DIR}/numbers/converge_puresim_table.txt"

	# SI BR+Noise
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/BRwithNoise_accuracy_astext.txt" "${PAPER_DIR}/numbers/BRwithNoise_accuracy_astext.txt"
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/BRwithNoise_PickSecond_accuracy_astext.txt" "${PAPER_DIR}/numbers/BRwithNoise_PickSecond_accuracy_astext.txt"

	# SI TP with Gaussian noise
	cp "${STAT_PLOT_DIR}/model_empirical_roundbyround/TP_GAUSS_RESULT.tsv" "${PAPER_DIR}/numbers/TP_GAUSS_RESULT.tsv"

	# SI Bayes tipping rate
	cp "${STAT_PLOT_DIR}/bayestippingpoint/tippinglikelihoodbynetworksize.tsv" "${PAPER_DIR}/numbers/Bayes_tipping_likelihood_by_networksize.tsv"

	# Name in memory vs. output stats
	SEVEN_FIVE_CBBB_FILE="${STAT_PLOT_DIR}/model_empirical_roundbyround/M-12_noise-0_pop-FIFO_update-PENALIZE/top_name_ratio_output_explore_22.csv"
	head -n 1 "${SEVEN_FIVE_CBBB_FILE}" > "${PAPER_DIR}/numbers/SC_CBBB_Tip_SevenFive_memory_output.csv"
	grep "7:12,CBBB2018" "${SEVEN_FIVE_CBBB_FILE}" >> "${PAPER_DIR}/numbers/SC_CBBB_Tip_SevenFive_memory_output.csv"


}

