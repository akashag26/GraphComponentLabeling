
import java.io.*;
import java.util.*;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Random;

// This class represents a directed graph using adjacency list
// representation
class UnionLabel
{
    private Integer V;   // No. of vertices
    private LinkedList<Integer> adj[]; //Adjacency Lists
    private int totaledges=0;
    private Map<Integer, List<Integer>> adjacencyList;
    private int count;
    // private int[] C;
    // private boolean[] F;
    private Map<Integer,Integer> c1;
    private Map<Integer,Boolean> f1;
    private int[] id;
    
    public void MakeSet(int N) {
        count = N;
        id = new int[N];
        for (int i = 0; i < N; i++) {
            id[i] = i;
        }
    }
    
    public int count() {
        return count;
    }
    
    public int find(int p) {
        int root = p;
        while (root != id[root])
            root = id[root];
        while (p != root) {
            int newp = id[p];
            id[p] = root;
            p = newp;
        }
        return root;
    }
    
    public void union(int p, int q) {
        int rootP = find(p);
        int rootQ = find(q);
        // if (rootP == rootQ) return;
        if(id[rootP]>rootQ)
        {
            id[rootP] = rootQ;
            count--;
        }
        //System.out.print(rootQ+" ");
    }
    
    public void Random_Undirected_Graph(Integer v)
    {
         adjacencyList = new HashMap<Integer, List<Integer>>();
        c1 = new HashMap<Integer, Integer>();
        f1 = new HashMap<Integer, Boolean>();
        for (Integer i = 1; i <= v; i++){
            c1.put(i-1, i-1);
            f1.put(i-1, true);
            adjacencyList.put(i-1, new LinkedList<Integer>());
        }
        
    }
    
    public void setEdge(Integer to, Integer from)
    {
        if (to > adjacencyList.size() || from > adjacencyList.size())
            System.out.println("The vertices does not exists");
        
        List<Integer> sls = adjacencyList.get(to);
        sls.add(from);
        List<Integer> dls = adjacencyList.get(from);
        dls.add(to);
    }
    
    public List<Integer> getEdge(Integer to)
    {
        if (to > adjacencyList.size()-1)
        {
            System.out.println("The vertices does not exists");
            return null;
        }
        return adjacencyList.get(to);
    }
    
    // Constructor
    UnionLabel(Integer v)
    {
        V = v;
        adj = new LinkedList[v];
        for (Integer i=0; i<v; ++i)
            adj[i] = new LinkedList();
    }
    
    // Function to add an edge Into the graph
    void addEdge(Integer v,Integer w)
    {
        adj[v].add(w);
    }
    
    void callCPU(int i){
        List<Integer> edges1=new LinkedList<Integer>();
        edges1=adjacencyList.get(i);
        Iterator<Integer> iterator = edges1.iterator();
        while(iterator.hasNext())
        {
            Integer j=iterator.next();
            if (find(i) != find(j))
         		 {
                     union(j,i);
                 }
        }
    }
    
    
    // Driver method to
    public static void main(String args[])
    {
        Integer total_edges;
        Integer e=976;
        try
        {
            int minV = (int) Math.ceil((1 + Math.sqrt(1 + 8 * e)) / 2);
            int maxV = e + 1;
            
            Random random = new Random();
            Integer v=25000;
            System.out.println("Random graph has "+v+" vertices");
            
            UnionLabel g = new UnionLabel(v);
            g.Random_Undirected_Graph(v);
            g.MakeSet(v);
            int number_of_connected_components=4096;
            
            int k=v/number_of_connected_components;
            
            for(int s=0;s<number_of_connected_components;s++)
            {
                // System.out.print((s+1)+" Component   ");
                Integer count = 1;
                int rand=k*s;
                //System.out.print(k+"   "+rand+"   ");
                Integer  to, from;
                while (count <= e)
                {
                    to = Math.abs(random.nextInt(k) + rand);
                    from = Math.abs(random.nextInt(k) + rand);
                    //System.out.println(to);
                    g.setEdge(to, from);
                    count++;
                }
                // System.out.println();
            }
            System.out.println("The Adjacency List Representation of the graph is: ");
            
            List<Integer> edges1=new LinkedList<Integer>();
            for (Integer i = 0; i < v; i++){
                edges1=g.adjacencyList.get(i);
                
                
                Object[] st = edges1.toArray();
                for (Object s : st) {
                    if (edges1.indexOf(s) != edges1.lastIndexOf(s)) {
                        edges1.remove(edges1.lastIndexOf(s));
                    }
                }
                Iterator<Integer> iterator = edges1.iterator();
                while(iterator.hasNext())
                {
                    Integer value = iterator.next();
                    if (Integer.valueOf(i).equals(value))
                    {
                        iterator.remove();
                    }
                }
            }
            
        	   Integer start_count=0;
            for(Integer i=0;i<v;i++)
            {
                start_count+=g.adjacencyList.get(i).size();
            }
            edges1=null;
            System.out.println("List Created Starting Connected Component check");
            long start_time = System.nanoTime();
            for(Integer j=0;j<v;j++)
                g.callCPU(j);
            for(Integer j=0;j<v;j++)
            {
                g.c1.put(j, g.find(j));
            }
            long end_time = System.nanoTime()-start_time;
            System.out.println("Total Time in Seconds: "+end_time/(1000*1000));
            System.out.println("Total number of connected components"+g.count);
            
        }
        catch (Exception E) 
        {
            E.printStackTrace();
            System.out.println("Something went wrong");
        }
        //sc.close();
    }
    
}
