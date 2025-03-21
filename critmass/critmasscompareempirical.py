# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

import sys, os, os.path
import numpy as np
import pandas as pd
import time
import argparse
from statistics import mean
import random
from simulationhelpers import *
from collections import Counter as counter
from pathlib import Path

parent_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(parent_dir))


from agents.tp_agent import TP_Agent
from agents.br_agent import BR_Agent
from agents.cb_agent import CB_Agent
from agents.confed_agent import Confed_Agent


MAX_ROUND = 150
HALT_EMPIRICAL = False
USE_EMPIRICAL_MEMORY = False
EMPIRICAL_MEMORY_PATH = ""

OUTPUT_DIR = ""
MEM_SIZE = 0
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "PENALIZE"

COL_SEP = "\t"
POSSIBLE_AGENT_TYPES = ['TP', 'BR', 'CB']



def initialize_network(N, CM, AGENT_TYPE):
	agent_dict_base = {}
	for curr_ID in range(N):
		if curr_ID < CM:
			agent_dict_base[curr_ID] = Confed_Agent(curr_ID, MEM_SIZE, ['new'], 'FIFO', 'new')
			agent_dict_base[curr_ID].activate_confed_agent()
		else:
			if AGENT_TYPE == 'TP':
				curr_agent = TP_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
			elif AGENT_TYPE == 'BR':
				curr_agent = BR_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE, 0.0)
			elif AGENT_TYPE == 'CB':
				curr_agent = CB_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
			else:
				raise Exception("Non-implemented agent type specified")
			curr_agent.seed_full_memory('old')
			agent_dict_base[curr_ID] = curr_agent
	return agent_dict_base


def initialize_network_empirical_seed(N, CM, AGENT_TYPE, CONFED_SEED, EMP_MEMS):
	agent_dict_base = {}
	for curr_ID in range(N):
		if curr_ID < CM:
			agent_dict_base[curr_ID] = Confed_Agent(curr_ID, MEM_SIZE, [CONFED_SEED], 'FIFO', CONFED_SEED)
			agent_dict_base[curr_ID].activate_confed_agent()
		else:
			CURR_MEM = EMP_MEMS.pop(0)
			if (len(EMP_MEMS) == 0):
				EMP_MEMS.append(CURR_MEM)
			CURR_MEM = CURR_MEM.split(";")

			if AGENT_TYPE == 'TP':
				curr_agent = TP_Agent(curr_ID, MEM_SIZE, CURR_MEM, "FIFO", UPDATE_RULE)
			elif AGENT_TYPE == 'BR':
				curr_agent = BR_Agent(curr_ID, MEM_SIZE, CURR_MEM, "FIFO", UPDATE_RULE, 0.0)
			elif AGENT_TYPE == 'CB':
				curr_agent = CB_Agent(curr_ID, MEM_SIZE, CURR_MEM, "FIFO", UPDATE_RULE)
			else:
				raise Exception("Non-implemented agent type specified")
			curr_agent.seed_full_memory_fully_specified(CURR_MEM)
			agent_dict_base[curr_ID] = curr_agent
	return agent_dict_base



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global EMP_DATA_PATH, MEM_SIZE, NUM_CONFEDS
	global OUTPUT_DIR, UPDATE_RULE, HALT_EMPIRICAL, USE_EMPIRICAL_MEMORY, EMPIRICAL_MEMORY_PATH

	if args.empiricaldata is None:
		raise Exception("Need to specify path to empirical network data")
	else:
		EMP_DATA_PATH = args.empiricaldata

	if args.M is None:
		raise Exception("Need to specify memory queue size")
	else:
		MEM_SIZE = args.M

	if args.empiricalhaltpoint is None:
		HALT_EMPIRICAL = False
	elif args.empiricalhaltpoint == "TRUE":
		HALT_EMPIRICAL = True
	else:
		HALT_EMPIRICAL = False


	if args.empiricalmemory is None:
		USE_EMPIRICAL_MEMORY = False
	else:
		EMPIRICAL_MEMORY_PATH = args.empiricalmemory
		USE_EMPIRICAL_MEMORY = True


	if args.updaterule is None:
		raise Exception("Need to provide memory update procedure (BUFFER or PENALIZE)")
	elif args.updaterule not in ["BUFFER", "PENALIZE"]:
		raise Exception("Possible memory update procedures are BUFFER or PENALIZE")
	else:
		UPDATE_RULE = args.updaterule

	if args.outputdir is None:
		raise Exception("Need to specify output director")
	else:
		OUTPUT_DIR = args.outputdir


def load_network_line(empirical_line):
	curr_network_list = empirical_line.split('\t')
	instance_id = curr_network_list[0]
	NETWORK_SIZE = int(curr_network_list[1])
	CM = float(curr_network_list[2])
	FLIPPED = str(curr_network_list[3])
	MAX_FLIP_PROP = float(curr_network_list[4])
	FLIP_ROUND = int(curr_network_list[5])
	ROUND_CONFED_ACTIVE = int(curr_network_list[6])
	EMPIRICAL_HALT_POINT = int(curr_network_list[7])

	NUM_CONFEDS = int(round(CM * NETWORK_SIZE))
	# if FLIPPED == "TRUE":
	# 	print(instance_id, CM, NETWORK_SIZE, CM * NETWORK_SIZE, NUM_CONFEDS)

	return instance_id, NETWORK_SIZE, NUM_CONFEDS, FLIPPED, MAX_FLIP_PROP, FLIP_ROUND, ROUND_CONFED_ACTIVE, EMPIRICAL_HALT_POINT



if __name__ == "__main__":
	start_time = time.time()
	print("Running critical mass (tipping point) simulation... ", end = "")

	random.seed()

	parser = argparse.ArgumentParser(description = "Convergence point")
	parser.add_argument("--empiricaldata", type=str)
	parser.add_argument("-M", help="Memory buffer size", type=int)
	parser.add_argument("--empiricalhaltpoint", help="Whether to stop at the max empirical round number or go beyond", type=str)
	parser.add_argument("--empiricalmemory", help="Whether to seed empirical memory or use pure simulation", type=str)
	parser.add_argument("--updaterule", help="Memory addition procedure: penalized or buffer", type=str)
	parser.add_argument("--outputdir", help="Output directory", type=str)
	parse_args_and_defaults(args = parser.parse_args())

	OUTPUT_RESULTS_PATH = os.path.join(OUTPUT_DIR, "empirical_flipping_compare_puresum.tsv")

	TOTAL_SIMULATIONS = set_total_simulation_limit()

	# Add in seeding with empirical memory...
	if USE_EMPIRICAL_MEMORY:
		EMP_MEM_DF = pd.read_csv(EMPIRICAL_MEMORY_PATH, sep='\t')



	with open(EMP_DATA_PATH, 'r') as emp_data_file:
		next(emp_data_file) # skip header
		with open(OUTPUT_RESULTS_PATH, 'w') as output_f:

			header_list = ["instance_id", "AGENT_CLASS", "sim_num", "NETWORK_SIZE", "NUM_CONFEDS", "FLIPPED", "MAX_FLIP_PROP", "FLIP_ROUND", "ROUND_CONFED_ACTIVE", "round_num", "abs_diff"]
			header_string = COL_SEP.join(header_list)
			output_f.write(header_string+"\n")

			for line in emp_data_file:
				instance_id, NETWORK_SIZE, NUM_CONFEDS, FLIPPED, MAX_FLIP_PROP, FLIP_ROUND, ROUND_CONFED_ACTIVE, EMPIRICAL_HALT_POINT = load_network_line(line)

				if USE_EMPIRICAL_MEMORY:
					CURR_EMP_MEMS_DF = EMP_MEM_DF[EMP_MEM_DF['instance_id'] == int(instance_id)]
					CONFED_SEED = str(CURR_EMP_MEMS_DF['confed_seed'].iloc[0])
					CURR_EMP_MEMS_LIST = CURR_EMP_MEMS_DF['mems'].tolist()
				
				# handle the odd-numbered empirical networks
				if NETWORK_SIZE % 2 == 1:
					NETWORK_SIZE += 1

				if FLIPPED == "TRUE":
					# print("network: ", instance_id, end = "")
					# print(" ", NETWORK_SIZE, NUM_CONFEDS,  MAX_FLIP_PROP)

					# run simulation
					for AGENT_CLASS in POSSIBLE_AGENT_TYPES:
						for sim_num in range(TOTAL_SIMULATIONS):
							if USE_EMPIRICAL_MEMORY:
								EMP_MEMS_COPY = CURR_EMP_MEMS_LIST.copy()
								agent_dict = initialize_network_empirical_seed(NETWORK_SIZE, NUM_CONFEDS, AGENT_CLASS, CONFED_SEED, EMP_MEMS_COPY)
							else:
								agent_dict = initialize_network(NETWORK_SIZE, NUM_CONFEDS, AGENT_CLASS)

							model_flipped = False

							if HALT_EMPIRICAL:
								HALT_ROUND = EMPIRICAL_HALT_POINT
							else:
								HALT_ROUND = MAX_ROUND

							for round_num in range(1,HALT_ROUND+1):
								produced_names = play_round(agent_dict)
								assert len(produced_names) == NETWORK_SIZE - NUM_CONFEDS
								# print(produced_names)

								if USE_EMPIRICAL_MEMORY:
									converged, num_news, prop_new_names = check_convergence(produced_names, CONFED_SEED)
								else:
									converged, num_news, prop_new_names = check_convergence(produced_names, 'new')

								"""
								don't look when literally converged (by the stringent definition)
								rather check when frac_alt reached highest empirical level
								"""
								if prop_new_names >= MAX_FLIP_PROP:
									abs_diff = abs(round_num - FLIP_ROUND)
									output_list = [str(instance_id), str(AGENT_CLASS), str(sim_num), str(NETWORK_SIZE), str(NUM_CONFEDS), FLIPPED, str(MAX_FLIP_PROP), str(FLIP_ROUND), str(ROUND_CONFED_ACTIVE), str(round_num), str(abs_diff)]
									output_string = COL_SEP.join(output_list)
									output_f.write(output_string+"\n")
									model_flipped = True
									break
							if not model_flipped:
								abs_diff = MAX_ROUND
								output_list = [str(instance_id), str(AGENT_CLASS), str(sim_num), str(NETWORK_SIZE), str(NUM_CONFEDS), FLIPPED, str(MAX_FLIP_PROP), str(FLIP_ROUND), str(ROUND_CONFED_ACTIVE), str(round_num), str(abs_diff)]
								output_string = COL_SEP.join(output_list)
								output_f.write(output_string+"\n")



