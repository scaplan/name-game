# encoding: utf-8

import sys, os, os.path
import numpy as np
import time
import argparse
import math
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

from aux.loadstandarddata import print_progress_bar


DEBUG_MODE = False
MAX_ROUND = 75

WORD_DIST_SIZE = 10
OUTPUT_CONVERGE_FILENAME = ""
MEM_SIZE = 0
FIFO_REMOVAL = "FIFO"
UPDATE_RULE = "PENALIZE"

TP_THRESHOLD = -1

COL_SEP = "\t"
POSSIBLE_AGENT_TYPES = ['TP', 'BR', 'CB', 'Luce']



def initialize_network():
	agent_dict_base = {}
	for curr_ID in range(NETWORK_SIZE):
		if AGENT_CLASS == 'TP':
			curr_agent = TP_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
		elif AGENT_CLASS == 'BR':
			curr_agent = BR_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE, 0.0)
		elif AGENT_CLASS == 'CB':
			curr_agent = CB_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
		elif AGENT_CLASS == 'Luce':
			curr_agent = Luce_Agent(curr_ID, MEM_SIZE, ['old'], "FIFO", UPDATE_RULE)
		else:
			raise Exception("Non-implemented agent type specified")
		agent_dict_base[curr_ID] = curr_agent
	return agent_dict_base



def parse_args_and_defaults(args: argparse.Namespace) -> None:
	global AGENT_CLASS, NETWORK_SIZE, MEM_SIZE
	global OUTPUT_CONVERGE_FILENAME, WORD_DIST_SIZE, TP_THRESHOLD

	if args.agents is None:
		raise Exception("Need to specify agent class")
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

	if args.W is None:
		raise Exception("Need to specify size of sampling distribution (words)")
	else:
		WORD_DIST_SIZE = args.W


	if args.M is None:
		raise Exception("Need to specify memory queue size")
	else:
		MEM_SIZE = args.M


	if args.outputconvergefile is None:
		raise Exception("Need to specify output file for flipping")
	else:
		OUTPUT_CONVERGE_FILENAME = args.outputconvergefile


	TP_THRESHOLD = MEM_SIZE-math.floor(MEM_SIZE/math.log(MEM_SIZE))




if __name__ == "__main__":
	# start_time = time.time()

	random.seed()

	parser = argparse.ArgumentParser(description = "Convergence point")
	parser.add_argument("--agents", help="Which agents to use (TP, BR, CB)", type=str)
	parser.add_argument("-N", help="Network size (number of agents); must be even", type=int)
	parser.add_argument("-W", help="Number of unique types in the initial sampling distribution", type=int)
	parser.add_argument("-M", help="Memory buffer size", type=int)
	parser.add_argument("--outputconvergefile", help="Output path for recording final p(convergence)", type=str)
	parse_args_and_defaults(args = parser.parse_args())

	# print(AGENT_CLASS, NETWORK_SIZE, WORD_DIST_SIZE, " -- ", end="")
	CURR_PREPEND_STRING = " ".join([str(AGENT_CLASS), str(NETWORK_SIZE), str(WORD_DIST_SIZE), " -- "])
	results = []

	TOTAL_SIMULATIONS = set_total_simulation_limit()

	with open(OUTPUT_CONVERGE_FILENAME, 'a') as output_f:

		for sim_num in range(TOTAL_SIMULATIONS):

			words = generate_words(WORD_DIST_SIZE, 'z') # generate word list, "z" for zipfian

			agent_dict = initialize_network()
			first_converged = -1

			for i in range(NETWORK_SIZE):
				agent = agent_dict.get(i)
				word = getword(words)
				agent.seed_single_name_memory(word)

			for round_num in range(MAX_ROUND):
				choices = play_round(agent_dict)

				# converged = check_convergence_types(choices)
				converged, _, _ = check_convergence(choices, 'any')
				if converged:
					results.append(round_num+1)
					break

			print_progress_bar(sim_num, TOTAL_SIMULATIONS, CURR_PREPEND_STRING)

		output_list = [AGENT_CLASS, str(NETWORK_SIZE), str(MEM_SIZE),
					   str(WORD_DIST_SIZE), str(len(results)), str(TOTAL_SIMULATIONS),
					   str(round(np.mean(results), 2)), str(round(np.std(results), 2))
					   ]
		output_string = COL_SEP.join(output_list)
		output_f.write(output_string+"\n")


	if DEBUG_MODE:
		print('converged = ', len(results), '%.2f' % np.mean(results), '%.2f' % np.std(results))
		

