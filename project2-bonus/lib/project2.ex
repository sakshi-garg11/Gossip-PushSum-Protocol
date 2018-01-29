defmodule Project2 do
  use GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end


   def main(args\\[]) do
    arguments = args
    numInput = length(arguments) 

    if (numInput<3) do
      IO.puts "INVALID ARGUMENT"
      :init.stop()
    end
    
    numNodes=Enum.at(arguments,0)
    topology_name=Enum.at(arguments,1)
    algo =Enum.at(arguments,2)
    killNodes=Enum.at(arguments,3)
    power=numNodes|>String.to_integer|>:math.sqrt|>:math.ceil|>round

    numNodes=
    
    cond do
    (topology_name == "2D")
     -> :math.pow(power,2)|>round|>Integer.to_string
    
    (topology_name == "imp2D")
     -> :math.pow(power,2)|>round|>Integer.to_string
    
    (topology_name == "full")
     -> numNodes
   
    (topology_name ==  "line")
     -> numNodes
    end 
    
    nodes= String.to_integer(numNodes)
    IO.inspect (for i <- 1..nodes do 
      spawn(fn->Project2.Worker.start_link(Integer.to_string(i)|>String.to_atom) end)
    end)


    Project2.Dist.start_connection(:project2)
    start_link(numNodes)
    IO.puts "... build topology"
    intVal=numNodes|>String.to_integer|>:math.sqrt|>:math.ceil|>round
    
    map=MapSet.new(Enum.into(1..String.to_integer(numNodes),[]))|>MapSet.to_list|>List.to_tuple
    
    topo= topology_name|>String.to_atom

    topology(topo, numNodes, intVal, map)
    
    IO.puts "... start protocol"
    GenServer.cast({:Server,Node.self()},{:add_time,:os.system_time(:millisecond)})
    
    protocol(algo, numNodes, intVal, topology_name)
    #bonus
    kill=String.to_integer(numNodes)
    match=Enum.map(1..kill,fn(i)->i end)
    ranTake=Enum.take_random(match,String.to_integer(killNodes))
    Enum.map( ranTake,fn(i)->GenServer.stop({Integer.to_string(i)|>String.to_atom,Node.self()})end);
    delay()
 end
 def delay do
  GenServer.cast({:Server,Node.self()},{:check_state,""})
  Process.sleep(1000)
  delay()
end

  def topology(topos, numNodes, intVal, map) do
    
      cond  do
        topos == :full->
          for i <- 1..String.to_integer(numNodes) do
            GenServer.call({Integer.to_string(i)|>String.to_atom,Node.self()},{:complete,map,i},:infinity)
          end
          
        topos == :line->
          for i <- 2..String.to_integer(numNodes) do
            GenServer.call({Integer.to_string(i)|>String.to_atom,Node.self()},{:line,i-1,i},:infinity)
          end
          for i<- 1..(String.to_integer(numNodes)-1) do
            GenServer.call({Integer.to_string(i)|>String.to_atom,Node.self()},{:line,i+1,i},:infinity)
          end
              
        topos == :"2D"->
          for rowVal <- 1..intVal do
            for columnVal <- 1..intVal do
              for i <- 1..4 do
              matrix=(rowVal-1)*intVal+(columnVal-1)+1
              matrix=
              cond do
                i == 1->matrix+1;
                i == 2->matrix-1;
                i == 3->matrix-intVal
                i == 4->matrix+intVal
              end
              if matrix<=0 || matrix>intVal*intVal do
                nil
                else
                  change=(rowVal-1)*intVal+(columnVal-1)+1
                GenServer.call({change|>Integer.to_string|>String.to_atom,Node.self()},{:line,matrix,change})
              end
              end
            end
          end
        topos ==:imp2D->
          for rowVal <- 1..intVal do
            for columnVal <- 1..intVal do
              for i <- 1..4 do
                matrix=(rowVal-1)*intVal+(columnVal-1)+1
                matrix=
                cond do
                    i == 1->matrix+1;
                    i == 2->matrix-1;
                    i == 3->matrix-intVal
                    i == 4->matrix+intVal
                end
                if matrix<=0 || matrix>intVal*intVal do
                  nil
                else
                  change=(rowVal-1)*intVal+(columnVal-1)+1
                 GenServer.call({change|>Integer.to_string|>String.to_atom,Node.self()},{:line,matrix,change},:infinity)
                end
                calculate=Enum.random(0..intVal*intVal) 
                position=(rowVal-1)*intVal
                GenServer.call({(position+columnVal)|>Integer.to_string|>String.to_atom,Node.self()},{:line,calculate,(position+columnVal)},:infinity)
              end
            end
        end
      end
    
 end 

  def protocol(algo, numNodes, intVal, topology_name) do
    cond do
      algo == "gossip"->
        any= numNodes|>String.to_integer|>:rand.uniform
        GenServer.cast({any|>Integer.to_string|>String.to_atom,Node.self()},{:msg,"hello",any,algo,4})
     algo == "push-sum"->
       tName = topology_name|>String.to_atom
       check_topo=
        
          cond do
            tName == :full->numNodes|>String.to_integer
            tName == :line->numNodes|>String.to_integer
            tName == :"2D"->intVal*intVal
            tName == :imp2D->intVal*intVal
        end
        for i <- 1..check_topo do
          GenServer.call({i|>Integer.to_string|>String.to_atom,Node.self()},{:add_state,"",i},:infinity)
        end
        any=Enum.random(0..check_topo)
        GenServer.cast({any|>Integer.to_string|>String.to_atom,Node.self()},{:msg,{},any,algo,0})
    end
  end

  def init(args) do
    initArg= String.to_integer(args)
    {:ok,{MapSet.new(Enum.into (for i <- 1..initArg do 
      if GenServer.whereis({i|>Integer.to_string|>String.to_atom,Node.self()}) != nil do 
        i 
      else  
      end 
      end),[]),%{}}}
  end

  def handle_call({check,name},_from,state) do
    cond do
      check == :add_val->
        map=Map.put(elem(state,1),name,1)
        state=Tuple.delete_at(state,1)
        state=Tuple.insert_at(state,1,map)
        if length(Map.to_list(elem(state,1)))==length(MapSet.to_list(elem(state,0))) do
          IO.puts(:os.system_time(:millisecond)-elem(state,2))
          for i <- MapSet.to_list(elem(state,0)) do
            GenServer.stop({Integer.to_string(i)|>String.to_atom,Node.self()})
          end
          Process.exit(self(),:normal)
        end
        {:reply,"",state}
        check == :link->
      {:reply,state,state}
    end
  end
 
  def handle_cast({check,time},state) do
    cond do
      check == :add_time->{:noreply,Tuple.append(state,time)}
      check == :check_state->
        val=elem(state,0)
        val=MapSet.new(Enum.into(MapSet.to_list(val),[],fn(i)-> if GenServer.whereis({i|>Integer.to_string|>String.to_atom,Node.self()}) != nil do i end end))
        val=MapSet.delete(val,nil)
        state=Tuple.delete_at(state,0)
        {:noreply,Tuple.insert_at(state,0,val)}
    end
  end

  
end