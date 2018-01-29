defmodule Project2.Worker do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
       
    end

    def init(:ok) do
        {:ok,{{},%{}}}
    end
    def cast_call(verify,input,argument,protocol) do
        GenServer.cast({Integer.to_string(argument)|>String.to_atom,Node.self()},{verify,input,argument,protocol})
    end
    def handle_call({verify , input , argument},_from,state) do
        element0=elem(state,0)
        element1=elem(state,1)
      cond do
         verify == :complete->
                {:reply,"",{Tuple.delete_at(input, argument-1), element1} }
        
         verify == :line->
           var=Tuple.append(element0,input)
           {:reply,"",{var, element1}}

         verify == :add_state->
                map=%{}
                map=Map.put(map,"event",{argument,1})
                map=Map.put(map,"equity",1)
                {:reply,"",{element0,map}}
         
         verify == :link->
                {:reply,state,state}
      end
    end
    def handle_cast({:msg , input , argument,protocol ,sleep},state) do
        element0=elem(state,0)
        
            wait_time=10
            var=:rand.uniform(tuple_size(element0))
            element2=elem(element0,var-1)
            cond do
                 sleep == 1->
                    if GenServer.whereis({Integer.to_string(element2)|>String.to_atom,Node.self()}) != nil do
                         GenServer.cast({Integer.to_string(element2)|>String.to_atom,Node.self() },{:msg,input,element2,protocol,0})
                         Process.sleep(wait_time)
                    else
                   end
                   GenServer.cast({Integer.to_string(argument)|>String.to_integer|>Integer.to_string|>String.to_atom,Node.self()},{:msg,input,argument,protocol,1})
                   {:noreply,state}
                 sleep != 1 ->""
            end
            cond do
                protocol == "gossip"->
                    map=elem(state,1)
                    map1=elem(state,0)
                    if Map.get(map,input,0)>10 do
                    
                        GenServer.call({:Server,Node.self()},{:add_val,argument},:infinity)
                        GenServer.stop({Integer.to_string(argument)|>String.to_atom,Node.self()})
                        {:noreply,state}
                     else
                        map=Map.put(map,input,Map.get(map,input,0)+1)
                        see=elem(map1,var-1)
                        if GenServer.whereis({Integer.to_string(see)|>String.to_atom,Node.self()}) != nil do
                           
                                GenServer.cast({Integer.to_string(see)|>String.to_atom,Node.self() },{:msg,input,see,protocol,0})
                          else
                        end
                        Process.sleep(wait_time)
                        GenServer.cast({Integer.to_string(argument)|>String.to_atom,Node.self()},{:msg,input,argument,protocol,1})
                        {:noreply,{map1,map}}
                    end
                    protocol == "push-sum"->
                        map=elem(state,1)
                        map1=elem(state,0)
                        if tuple_size(input)==0 do
                                notice=elem(map1,var-1)
                                {sInitial,wInitial}=Map.get(map,"event")
                                if GenServer.whereis({Integer.to_string(notice)|>String.to_atom,Node.self()}) != nil do
                                    GenServer.cast({Integer.to_string(notice)|>String.to_atom,Node.self() },{:msg,{sInitial/2,wInitial/2},notice,protocol,sleep})
                                else
                                    GenServer.cast({Integer.to_string(argument)|>String.to_atom},{:msg,input,argument,protocol,sleep})
                                end
                                 
                                map=Map.put(map,"event",{sInitial+sInitial/2,wInitial+wInitial/2})
                                map=Map.put(map,"equity",1)
                                {:noreply,{map1,map}}
                        else
                                if Map.get(map,"equity")>=3 do
                                    saw=elem(map1,var-1)
                                        if GenServer.whereis({Integer.to_string(saw)|>String.to_atom,Node.self()}) != nil do
                                           GenServer.cast({Integer.to_string(saw)|>String.to_atom,Node.self() },{:msg,input,saw,protocol,sleep})
                                         else
                                            GenServer.cast({Integer.to_string(argument)|>String.to_atom,Node.self()},{:msg,input,argument,protocol,sleep})
                                        end
                                      
                                        GenServer.call({:Server,Node.self()},{:add_val,argument},:infinity)
                                    {:noreply,state}
                                    else
                                        val=Map.get(map,"event")
                                        sInitial=elem(val,0)
                                        wInitial=elem(val,1)
                                        s1=elem(input,0)
                                        w1=elem(input,1)
                                        ratio=sInitial/wInitial
                                        sAfter= s1+(sInitial/2)
                                        wAfter=w1+(wInitial/2)
                                        exp= (sAfter/wAfter)-ratio
                                        map=
                                        if abs(exp)<:math.pow(10,-10) do
                                            Map.put(map,"equity",Map.get(map,"equity")+1)
                                        else
                                            Map.put(map,"equity",1)
                                        end
                                        map=Map.put(map,"event",{sInitial+s1/2,wInitial+w1/2})
                                        take=elem(map1,var-1)
                                        if GenServer.whereis({Integer.to_string(take)|>String.to_atom,Node.self()}) != nil do
                                            GenServer.cast({Integer.to_string(take)|>String.to_atom,Node.self() },{:msg,{s1/2,w1/2},take,protocol,sleep})
                                            {:noreply,{map1,map}}
                                        else
                                            GenServer.cast({Integer.to_string(argument)|>String.to_atom,Node.self()},{:msg,input,argument,protocol,sleep})
                                            {:noreply,state}
                                        end
                                end

                        end
            end
        end

  
end
