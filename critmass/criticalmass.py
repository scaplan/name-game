# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

import sys, os, os.path
import numpy as np
import time
import argparse
from statistics import mean
import random
from simulationhelpers import *
from collections import Counter as counter
from pathlib import Path

parent_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(parent_dir))

from agents.luce_agent import Luce_Agent
from agents.tp_agent import TP_Agent
from agents.br_agent import BR_Agent
from agents.cb_agent import CB_Agent
from agents.confed_agent import Confed_Agent


MAX_ROUND = 75
PERCENT_LUCE = 0

OUTPUT_DIR = ""
OUTPUT_FLIP_FILENAME = ""
MEM_SIZE = 0
NUM_CONFEDS = 0
NUM_STANDARD_PEOPLE = 0
CM_STRING = ""
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "PENALIZE"

COL_SEP = "\t"
POSSIBLE_AGENT_TYPES = ['TP', 'BR', 'CB', 'Luce']


def get_random_BR_or_Luce_agent(i, M):
	global PERCENT_LUCE
	if random.randint(1, 100) <= PERCENT_LUCE:
		curr_agent = Luce_Agent(i, M, ['old'], "FIFO", UPDATE_RULE)
	else:
		curr_agent = BR_Agent(i, M, ['old'], "FIFO", UPDATE_RULE, 0.0)
	return curr_agent


def initialize_network():
	agent_dict_base = {}
	for curr_ID in range(NETWORK_SIZE):
		if curr_ID < NUM_CONFEDS:
			agent_dict_base[curr_ID] = Confed_Agent(curr_ID, MEM_SIZE, ['new'], 'FIFO', 'new')
			agent_dict_base[curr_ID].activate_confed_agent()
		else:
			if AGENT_CLASS == 'TP':
				curr_agent = TP_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
			elif AGENT_CLASS == 'BR':
				curr_agent = get_random_BR_or_Luce_agent(curr_ID, MEM_SIZE)
				# curr_agent = BR_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE, 0.0)
			elif AGENT_CLASS == 'CB':
				curr_agent = CB_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
			elif AGENT_CLASS == 'Luce':
				curr_agent = Luce_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
			else:
				raise Exception("Non-implemented agent type specified")
			curr_agent.seed_full_memory('old')
			agent_dict_base[curr_ID] = curr_agent
	return agent_dict_base



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global AGENT_CLASS, NETWORK_SIZE, MEM_SIZE, NUM_CONFEDS, PERCENT_LUCE
	global OUTPUT_DIR, NUM_STANDARD_PEOPLE, CM_STRING, OUTPUT_FLIP_FILENAME

	if args.agents is None:
		raise Exception("Need to specify agent class")
		# print("Defaulting to TP")
		# AGENT_CLASS = "TP"
	elif args.agents in POSSIBLE_AGENT_TYPES:
		AGENT_CLASS = args.agents
	else:
		raise Exception("Agents need to be in the set: ", POSSIBLE_AGENT_TYPES)


	if args.N is None:
		raise Exception("Need to specify number of agents (network size)")
	else:
		NETWORK_SIZE = args.N
	if NETWORK_SIZE % 2:
		raise Exception("Number of agents must be an even number")

	if args.CM is None:
		raise Exception("Need to specify number of confederate agents (defectors)")
	else:
		if args.CM < 0.0 or args.CM >= 1.0:
			raise Exception("Critical mass cannot be less than 0.0 or greater than 1.0 (inclusive)")
		CM_STRING = str(args.CM)
		NUM_CONFEDS = int(round(args.CM * NETWORK_SIZE))
		NUM_STANDARD_PEOPLE = NETWORK_SIZE - NUM_CONFEDS


	if args.M is None:
		raise Exception("Need to specify memory queue size")
	else:
		MEM_SIZE = args.M

	if args.outputdir is None:
		raise Exception("Need to specify output director")
	else:
		OUTPUT_DIR = args.outputdir

	if args.outputflipfile is None:
		raise Exception("Need to specify output file for flipping")
	else:
		OUTPUT_FLIP_FILENAME = args.outputflipfile

	if args.L is None:
		PERCENT_LUCE = 0
	elif args.L > 90 or args.L < 0:
		raise Exception("Percentage of Luce agents must be between 0 and 90")
	else:
		if AGENT_CLASS != "BR":
			raise Exception("Percent Luce simulation is only to be run with BR agents!")
		PERCENT_LUCE = args.L




if __name__ == "__main__":
	start_time = time.time()
	# print("Running CM (tipping point) simulation... ", end="")

	random.seed()

	parser = argparse.ArgumentParser(description = "Convergence point")
	parser.add_argument("--agents", help="Which agents to use (TP, BR, CB)", type=str)
	parser.add_argument("-N", help="Network size (number of agents); must be even", type=int)
	parser.add_argument('-L', nargs='?', help='Percentage of Luce agents to mix in; defaults to 0', type=int)
	parser.add_argument("-CM", help="Proportion of defectors (confederates) within the network (must be smaller between 0 and 1)", type=float)
	parser.add_argument("-M", help="Memory buffer size", type=int)
	parser.add_argument("--outputdir", help="Output directory", type=str)
	parser.add_argument("--outputflipfile", help="Output path for recording final p(adopt alternative)", type=str)
	parse_args_and_defaults(args = parser.parse_args())

	print(AGENT_CLASS, CM_STRING, NUM_CONFEDS, PERCENT_LUCE, NUM_STANDARD_PEOPLE, NETWORK_SIZE, " -- ", end="")
	OUTPUT_FILENAME_PROB_FLIP = os.path.join(OUTPUT_DIR, OUTPUT_FLIP_FILENAME)
	flipped_rounds = []


	TOTAL_SIMULATIONS = set_total_simulation_limit()

	# with open(OUTPUT_FILENAME_PROB_FLIP, 'a') as output_probflip_f:
	with open(OUTPUT_FILENAME_PROB_FLIP, 'w') as output_probflip_f:

		for sim_num in range(TOTAL_SIMULATIONS):
			agent_dict = initialize_network()
			first_flipped_round = -1

			for round_num in range(1,MAX_ROUND+1):

				produced_names = play_round(agent_dict)
				assert len(produced_names) == NETWORK_SIZE - NUM_CONFEDS
				converged, num_news, prop_new_names = check_convergence(produced_names, 'new')
				if converged and first_flipped_round < 0: 
					flipped_rounds.append(round_num)
					first_flipped_round = round_num

			output_list = [AGENT_CLASS, str(NETWORK_SIZE), str(PERCENT_LUCE), str(MEM_SIZE), str(CM_STRING), str(sim_num), str(prop_new_names), str(first_flipped_round)]
			output_string = COL_SEP.join(output_list)
			output_probflip_f.write(output_string+"\n")

	# clear previous line output and return curser to beginning...
	sys.stdout.write("\033[2K\r")
	sys.stdout.flush()
	CONFIG_STRING = " ".join([str(AGENT_CLASS), str(NETWORK_SIZE), str(NUM_CONFEDS)])
	if flipped_rounds:
		print(mean(flipped_rounds), " -- ", (time.time() - start_time), CONFIG_STRING, end="")
	else:
		print("NA", " -- ", (time.time() - start_time), CONFIG_STRING, end="")
		

