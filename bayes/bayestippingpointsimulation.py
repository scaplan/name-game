# encoding: utf-8

import sys, os, os.path
import numpy as np
import argparse
import random
from collections import Counter
from pathlib import Path

parent_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(parent_dir))

from agents.confed_agent import Confed_Agent
from agents.bayes_agent import Bayes_Agent

from aux.loadstandarddata import print_progress_bar


# Binomial process.... old name vs. new name
# Just simulation -- tipping point
# Priors over new vs. old...
# And change number of confederates


OUTPUT_FILENAME_MAIN = "bayes_tipping_point_simulation.csv"
COL_SEP = ","
MEM_SIZE = 12



def check_name_distro(agent_dict):
	name_counter = Counter()
	for index, agent in agent_dict.items():
		if not agent.check_is_confed():
			name_counter[agent.get_name()] += 1
	# print(name_counter)
	return name_counter.get('old', 0), name_counter.get('new', 0)



def play_round(agent_dict):
	global NETWORK_SIZE

	agent_indices = set(agent_dict.keys())

	assert not len(agent_indices) % 2
	"""
	need to have an even number of agents for round pairing completeness
	"""
	while agent_indices:
		# get pair of agents and remove from index set
		curr_index = random.choice(list(agent_indices))
		curr_agent = agent_dict.get(curr_index)
		agent_indices.remove(curr_index)
		partner_index = random.choice(list(agent_indices))
		partner_agent = agent_dict[partner_index]
		agent_indices.remove(partner_index)

		# get names
		curr_agent_name = curr_agent.get_name()
		partner_name = partner_agent.get_name()

		# compare and update
		curr_agent.compare_add_name(curr_agent_name, partner_name)
		partner_agent.compare_add_name(partner_name, curr_agent_name)
		agent_dict[curr_index] = curr_agent
		agent_dict[partner_index] = partner_agent


	return agent_dict


if __name__ == '__main__':

	# NETWORK_SIZE = 96
	# CONFED_PROP = 0.40
	# PRIOR = 0.8
	# UPDATE_SCALAR = 0.1

	print("Running Bayesian tipping point simulation... ", end="")

	parser = argparse.ArgumentParser(description = "Bayesian tipping point")
	parser.add_argument("--outputfileroundbyround", help="output filename for resulting analysis (round-by-round)", type=str)
	parser.add_argument("--outputfilesummary", help="output filename for resulting analysis (just tipping point)", type=str)
	args = parser.parse_args()


	if args.outputfileroundbyround is None:
		raise Exception("Need to specify output path for main analysis file (round by round)")
	else:
		OUTPUT_FILENAME_MAIN = args.outputfileroundbyround

	if args.outputfilesummary is None:
		raise Exception("Need to specify output path for main analysis file (summary)")
	else:
		OUTPUT_FILENAME_SUMMARY = args.outputfilesummary


	# write to CSV with all the param values and then a row per round, 
	with open(OUTPUT_FILENAME_MAIN, 'w') as output_file_roundbyround:
		with open(OUTPUT_FILENAME_SUMMARY, 'w') as output_file_summary:
			output_list = ["NETWORK_SIZE", "CONFED_PROP", "NUM_CONFEDS", "NUM_BAYESIANS", "PRIOR", "UPDATE_SCALAR", "ROUNDNUM", "NEW_NAMES", "OLD_NAMES", "NEW_PROP", "TIPPED", "RECONVERGED"]
			header_str = COL_SEP.join(output_list)
			output_file_roundbyround.write(header_str+"\n")

			output_list = ["NETWORK_SIZE", "CONFED_PROP", "PRIOR", "UPDATE_SCALAR", "FIRST_TIPPED"]
			header_str = COL_SEP.join(output_list)
			output_file_summary.write(header_str+"\n")

			total_simualations = 3*8*7*12

			param_config_num = 0


			# for simulation_number in range(5):
			# print("Simulation: ", simulation_number)
			for NETWORK_SIZE in [24, 48, 96]:
				# print()
				for CONFED_PROP in np.arange(0.1, 0.5, 0.05):
					CONFED_PROP = round(CONFED_PROP, 2)
					NUM_CONFEDS = round(NETWORK_SIZE * CONFED_PROP)
					NUM_BAYESIANS = NETWORK_SIZE - NUM_CONFEDS

					FIFTY_PERCENT = NUM_BAYESIANS / 2
					RECONVERGED_CUTOFF = NUM_BAYESIANS - 2

					for PRIOR in np.arange(0.6, 0.95, 0.05):
						PRIOR = round(PRIOR, 2)
						for UPDATE_SCALAR in np.arange(0.02, 0.6, 0.05):
							UPDATE_SCALAR = round(UPDATE_SCALAR, 2)
						

							agent_dict = {}

							for curr_ID in range(0, NETWORK_SIZE):
								if curr_ID < NUM_CONFEDS:
									agent_dict[curr_ID] = Confed_Agent(curr_ID, MEM_SIZE, ['old']*12, 'FIFO', 'new')
									agent_dict[curr_ID].activate_confed_agent()
								else:
									agent_dict[curr_ID] = Bayes_Agent(curr_ID, MEM_SIZE, ['old']*12, PRIOR, 'old', UPDATE_SCALAR)

							FIRST_TIPPED = 1000 # placeholder for non-tipping

							for round_num in range(1, 71):
								agent_dict = play_round(agent_dict)
								# save num agents (excluding confeds) producing each name
								num_old_output, num_new_output = check_name_distro(agent_dict)
								new_prop = round(num_new_output/(num_old_output+num_new_output), 2)
								# print(round_num, new_prop, num_new_output, FIFTY_PERCENT, num_old_output)

								reconverged = "True" if num_old_output <= 2 else "False"
								tipped = "True" if num_new_output > FIFTY_PERCENT else "False"

								if FIRST_TIPPED == 1000 and tipped == "True":
									FIRST_TIPPED = round_num

								output_list = [str(NETWORK_SIZE), str(CONFED_PROP), str(NUM_CONFEDS), str(NUM_BAYESIANS), str(PRIOR), str(UPDATE_SCALAR), str(round_num), str(num_new_output), str(num_old_output), str(new_prop), reconverged, tipped]
								output_string = COL_SEP.join(output_list)
								output_file_roundbyround.write(output_string+"\n")
							# print("NETWORK_SIZE:", NETWORK_SIZE, " CONFED_PROP:", CONFED_PROP, " UPDATE_SCALAR:", UPDATE_SCALAR, " reconverged:", reconverged, " tipped:", tipped)
							param_config_num += 1
							print_progress_bar(param_config_num, total_simualations)
							
							output_list = [str(NETWORK_SIZE), str(CONFED_PROP), str(PRIOR), str(UPDATE_SCALAR), str(FIRST_TIPPED)]
							output_string = COL_SEP.join(output_list)
							output_file_summary.write(output_string+"\n")



