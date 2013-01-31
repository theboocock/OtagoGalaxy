""" The nesi py queue function 

    Currently galaxy has no nice and easy way to parse
    and input queues to the nodes same with the runtime options simple function will
    need to created for each job runner tells it how to run with the queue

"""

def set_queue(runner_url,queue)
    """Sets the queue for """
    split_url=runner_url.split("/")
    i = 0
    new_runner_url
    for split in split_url:
        if i == 4:
            new_runner_url+= queue +'/'
        else:
            new_runner_url += split_url+"/"
        i++
