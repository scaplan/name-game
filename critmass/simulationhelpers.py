# encoding: utf-8

##  Author: Spencer Caplan
##  CUNY Graduate Center

import random
from collections import Counter as counter


def set_total_simulation_limit():
	return 3000
	# return 30   # for quick debugging


def play_round(agent_dict):
	agent_indices = list(agent_dict.keys())
	random.shuffle(agent_indices)
	assert not len(agent_indices) % 2 # need to have an even number of agents for round pairing completeness

	produced_names = []

	while agent_indices:
		# get pair of agents and remove from index list
		curr_index = agent_indices.pop()
		partner_index = agent_indices.pop()
		
		curr_agent = agent_dict.get(curr_index)
		partner_agent = agent_dict.get(partner_index)

		# get names
		curr_agent_name = curr_agent.get_name()
		partner_name = partner_agent.get_name()
		if not curr_agent.check_is_confed():
			produced_names.append(curr_agent_name)
		if not partner_agent.check_is_confed():
			produced_names.append(partner_name)

		# compare and update
		curr_agent.compare_add_name(curr_agent_name, partner_name)
		partner_agent.compare_add_name(partner_name, curr_agent_name)

	return produced_names


def sample_n_names(name_list, n):
	random.shuffle(name_list)
	return name_list[:n]


def check_convergence(name_list, new_name='any'):

	name_counter = counter(name_list)
	if new_name == 'any':
		top_name = name_counter.most_common(1)[0]
		top_name_freq = top_name[1]
		alternate_name_uses = len(name_list) - top_name_freq
		checked_freq = top_name_freq
	else:
		new_name_freq = name_counter.get(new_name, 0)
		alternate_name_uses = len(name_list) - new_name_freq
		checked_freq = new_name_freq
	if alternate_name_uses <= 2:
		return True, checked_freq, round(checked_freq/len(name_list), 2)
	else:
		return False, checked_freq, round(checked_freq/len(name_list), 2)


def check_convergence_types(name_list):
	num_names = len(set(name_list))
	if num_names <= 2:
		return True
	else:
		return False


def generate_words(W, distribution='z'):
	words = []

	if distribution.lower() == 'z':
		# zipfian distribution
		hn = 0.0
		for i in range(0, W):
			hn += 1.0/(i+1)
		for i in range(0, W):
			words.append({'name':str(i+1), 'p':1.0/((i+1)*hn)})
	else:
		# uniform distribution
		for i in range(0, W):
			words.append({'name':str(i+1), 'p':1.0/W})

	return words



def getword(words):
	rand = random.random()
	total = 0.0
	ind = len(words)-1
	for i in range(0, len(words)):
		total += words[i]['p']
		if total > rand:
			ind = i
			break
	return words[ind]['name']





