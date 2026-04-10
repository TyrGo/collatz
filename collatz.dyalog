:Namespace Collatz

    ⎕IO←1
    DRC←⍬
    CRLF←⎕UCS 13 10
    IndexHTML←''

    Trajectory←{⍵=1:,1 ⋄ ⍵,∇⊃(2|⍵)⌽(⍵÷2)(1+3×⍵)}

    ∇ Start port;z;wait;obj;evt;data
      IndexHTML←⊃⎕NGET '/app/index.html' 1
      'Conga' ⎕CY 'conga'
      DRC←Conga.Init ''
      z←DRC.Srv '' '' port 'HTTP'
      :If 0≠⊃z ⋄ ⎕←'Failed to start: ' z ⋄ →0 ⋄ :EndIf
      ⎕←'Collatz API listening on port ',⍕port

      :Repeat
          :Trap 0
              wait←DRC.Wait '' 5000
              :If 0=⊃wait
                  obj←2⊃wait
                  evt←3⊃wait
                  ⍝ ⎕←evt,' on ',obj
                  :If evt≡'HTTPHeader'
                      obj HandleRequest 4⊃wait
                  :EndIf
              :EndIf
          :Else
              ⎕←'Loop error: ',⎕DMX.(EM,' ',Message)
          :EndTrap
      :EndRepeat
    ∇

    ∇ obj HandleRequest raw;tokens;path;query;params
      tokens←' '(≠⊆⊢)⊃CRLF{(~⍺⍷⍵)⊆⍵}raw
      (path query)←Split 2⊃tokens
      ⎕←(⊃tokens),' ',path

      :Trap 0
          :Select path
          :Case '/trajectory'
              params←ParseQuery query
              obj Respond HandleTrajectory params
          :Case '/batch'
              params←ParseQuery query
              obj Respond HandleBatch params
          :CaseList (,'/') '/index.html'
              obj Respond 200 'text/html; charset=utf-8' (∊IndexHTML,¨⎕UCS 10)
          :Else
              obj Respond 404 'application/json' '{"error":"Not found"}'
          :EndSelect
      :Else
          ⎕←'Error: ',⎕DMX.(EM,' ',Message)
          obj Respond 500 'application/json' '{"error":"Internal server error"}'
      :EndTrap
    ∇

    ∇ r←HandleTrajectory params;n;seq;ns
      n←GetNum params 'n' 0
      :If (n<1)∨n>1000000
          r←400 'application/json' '{"error":"n must be 1-1000000"}'
          →0
      :EndIf
      seq←Trajectory n
      ns←⎕NS ''
      ns.start←n
      ns.steps←(≢seq)-1
      ns.peak←⌈/seq
      ns.sequence←seq
      r←200 'application/json' (⎕JSON ns)
    ∇

    ∇ r←HandleBatch params;from;to;rng;results;ns
      from←GetNum params 'from' 0
      to←GetNum params 'to' 0
      :If (from<1)∨(to<from)∨(to>1000000)
          r←400 'application/json' '{"error":"Invalid range"}'
          →0
      :EndIf
      :If 500<to-from
          r←400 'application/json' '{"error":"Range limited to 500 numbers"}'
          →0
      :EndIf
      rng←(from-1)+⍳(to-from)+1
      results←{
          seq←Trajectory ⍵
          ns←⎕NS ''
          ns.start←⍵
          ns.steps←(≢seq)-1
          ns.peak←⌈/seq
          ns
      }¨rng
      r←200 'application/json' (⎕JSON results)
    ∇

    ⍝ --- utils ---

    ∇ r←Split url;qpos
      qpos←url⍳'?'
      :If qpos>≢url ⋄ r←url '' ⋄ :Else ⋄ r←((qpos-1)↑url)(qpos↓url) ⋄ :EndIf
    ∇

    ∇ params←ParseQuery qs;pairs;kv
      :If 0=≢qs ⋄ params←0 2⍴'' ⋄ →0 ⋄ :EndIf
      pairs←('&'≠qs)⊆qs
      kv←{'='∊⍵:(⍵↑⍨¯1+⍵⍳'=')(⍵↓⍨⍵⍳'=') ⋄ ⍵ ''}¨pairs
      params←↑kv
    ∇

    ∇ v←GetNum(params key default);row;txt
      :If 0=≢params ⋄ v←default ⋄ →0 ⋄ :EndIf
      row←(params[;1])⍳⊂,key
      :If row>≢params ⋄ v←default
      :Else
          txt←⊃params[row;2]
          :Trap 0 ⋄ v←⌊⊃⊃(//)⎕VFI txt ⋄ :Else ⋄ v←default ⋄ :EndTrap
      :EndIf
    ∇

    ∇ obj Respond(status ct body);hdr;reason
      reason←(200 400 404 500⍳status)⊃'OK' 'Bad Request' 'Not Found' 'Internal Server Error' 'Unknown'
      hdr←'HTTP/1.1 ',(⍕status),' ',reason,CRLF
      hdr,←'Content-Type: ',ct,CRLF
      hdr,←'Content-Length: ',(⍕≢⎕UCS body),CRLF
      hdr,←'Access-Control-Allow-Origin: *',CRLF
      hdr,←'Connection: close',CRLF
      hdr,←CRLF
      {}DRC.Send obj (hdr,body)
    ∇

    ∇ Run
      Start 8080
    ∇

:EndNamespace
